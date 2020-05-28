#!/bin/bash

CNRM_VERSION=1.7.2
CNRM_NAME=cnrm-system

K8S_CLUSTER=
K8S_REGION=


function set_k8s_vars() {
    local choise="$1"
    local clusters=(${@:2})

    cl_pair=${clusters[$choise]}
    cluster=(${cl_pair//:/ })

    K8S_CLUSTER=${cluster[0]}
    K8S_REGION=${cluster[1]}
}

function get_cluster() {
    echo "Determine cluster ..."
    # list all clusters from current project to the user
    raw_clusters=$(gcloud container clusters list -q  2>/dev/null)
    echo "$raw_clusters"

    clusters=($(echo -e "$raw_clusters" | awk 'FNR > 1 {print $1 ":" $2 }' ))

    if [ "${#clusters[@]}" -eq 1 ] ; then
        set_k8s_vars 0 "${clusters[@]}"
    fi

    count=0
    echo -e "\nCHOISE    NAME  \tZONE"
    for cluster_pair in ${clusters[@]}; do
        cluster=(${cluster_pair//:/ })
        echo -e "$count   ->    ${cluster[0]}  ${cluster[1]}"
        let count++ 1
    done

    choise=0

    echo -en "\nEnter your choise for cluster [$choise] (${cluster_pair[$choise]}): "
    read  choise

    # check the read value is a number
    if ! [ -n "$choise" ] || ! [ "$choise" -eq "$choise" ] 2>/dev/null ; then
        choise=0
    fi

    set_k8s_vars $choise ${clusters[@]}
}

# uninstall config connector
function uninstall() {
    echo "Uninstall old version ..."

    DELETE="kubectl delete --all-namespaces --ignore-not-found --wait=true"
    $DELETE sts,deploy,po,svc,roles,clusterroles,clusterrolebindings -l cnrm.cloud.google.com/system=true
    $DELETE validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com
    $DELETE validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com
    $DELETE mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com
}


function configure_iam() {
    echo "Configure IAM ..."
    # create cnrm-system account if created this may fail
    gcloud iam service-accounts create $CNRM_NAME || true

    # give owner permissions on your project
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
           --member="serviceAccount:${CNRM_NAME}@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
           --role="roles/owner"

    # IAM policy binding between the IAM Service Account and the predefined Kubernetes service account
    gcloud iam service-accounts add-iam-policy-binding $CNRM_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
           --member="serviceAccount:$GOOGLE_CLOUD_PROJECT.svc.id.goog[${CNRM_NAME}/cnrm-controller-manager]" \
           --role="roles/iam.workloadIdentityUser"
}


function install() {
    echo "Install Config Connector ..."
    # temporary directory
    mkdir tmp
    cd tmp

    # download manifests
    gsutil cp gs://cnrm/$CNRM_VERSION/release-bundle.tar.gz release-bundle.tar.gz

    # extract
    tar zxvf release-bundle.tar.gz 1>/dev/null

    # Provide your project ID in the controller's installation manifest
    sed -i.bak "s/\${PROJECT_ID?}/$project_id/" install-bundle-workload-identity/0-cnrm-system.yaml

    # apply manifests
    kubectl apply -f install-bundle-workload-identity/

    # cleanup
    cd ..
    rm -rf tmp
}

function check_installation() {
    echo "Check installation ..."
    kubectl wait -n cnrm-system \
            --for=condition=Ready pod --all
}

function main() {
    set -e

    if [ "$GOOGLE_CLOUD_PROJECT" == "" ]; then
	      echo "Which is the google cloud project id? "
	      read GOOGLE_CLOUD_PROJECT
    fi

    # set project or make sure that the project is set
    gcloud config set project $GOOGLE_CLOUD_PROJECT

    # fetch values for K8S_CLUSTER and K8S_REGION
    get_cluster

    gcloud container clusters get-credentials $K8S_CLUSTER --region $K8S_REGION --project $GOOGLE_CLOUD_PROJECT

    # make sure that config connector is not installed
    uninstall

    # Setting up the identity
    configure_iam

    # install
    install

    # check installation
    check_installation
}


main
