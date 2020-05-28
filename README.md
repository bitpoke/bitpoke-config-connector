# Install GCP Config Connector

Config Connector is a Kubernetes add-on that allows customers to manage GCP resources, such as Cloud
Storage, through your cluster's API.

This scripts follows the [official
documentation](https://cloud.google.com/config-connector/docs/overview) and is optimized for
[Presslabs Dashboard](https://www.presslabs.com/dashboard/).

### Run installation script

Just run the following command in the console.
```bash
./install.sh
```

### Chose the cluster

If multiple Kubernetes clusters are available it will prompt to choose the one on which Presslabs
Dashboard is installed by choosing the right cluster.

### Check installation

In the end you should see a few messages similar to:

```
pod/cnrm-controller-manager-0 condition met
```
