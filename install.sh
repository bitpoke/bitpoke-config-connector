#!/bin/bash

CNRM_VERSION=1.7.0
REPO_NAME=dashboard-config-connector

if [ "$GOOGLE_CLOUD_PROJECT" == "" ]; then
	echo "Which is the google cloud project id? "
	read GOOGLE_CLOUD_PROJECT
fi

gcloud config set project $GOOGLE_CLOUD_PROJECT

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
rm -rf ../REPO_NAME

exit
