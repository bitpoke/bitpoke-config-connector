#!/bin/bash

CNRM_VERSION=1.7.2

if [ "$GOOGLE_CLOUD_PROJECT" == "" ]; then
	echo "Which is the google cloud project id? "
	read GOOGLE_CLOUD_PROJECT
fi

if [ "$K8S_CLUSTER" == "" ]; then
	  echo "Please provide the cluster name? "
	  read K8S_CLUSTER
fi

gcloud config set project $GOOGLE_CLOUD_PROJECT

gcloud container clusters get-credentials $K8S_CLUSTER --region europe-west4 --project $GOOGLE_CLOUD_PROJECT

# delete existing config connector
kubectl delete sts,deploy,po,svc,roles,clusterroles,clusterrolebindings --all-namespaces -l cnrm.cloud.google.com/system=true --wait=true
kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found --wait=true
kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true

gcloud iam service-accounts create cnrm-system

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
--member="serviceAccount:cnrm-system@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
--role="roles/owner"

gcloud iam service-accounts add-iam-policy-binding cnrm-system@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
--member="serviceAccount:$GOOGLE_CLOUD_PROJECT.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
--role="roles/iam.workloadIdentityUser"

gsutil cp gs://cnrm/$CNRM_VERSION/release-bundle.tar.gz release-bundle.tar.gz

tar zxvf release-bundle.tar.gz

sed -i.bak "s/\${PROJECT_ID?}/$project_id/" install-bundle-workload-identity/0-cnrm-system.yaml

kubectl apply -f install-bundle-workload-identity/

kubectl wait -n cnrm-system \
 --for=condition=Ready pod --all

# cleanup
rm -rf $PWD

exit
