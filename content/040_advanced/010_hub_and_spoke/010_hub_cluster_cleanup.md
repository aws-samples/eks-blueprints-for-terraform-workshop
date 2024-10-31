---
title: "[Optional] Argo CD Hub Cluster Cleanup"
weight: 10
hidden: true
---

In an Argo CD hub-spoke deployment architecture, the hub cluster is dedicated solely to running Argo CD. In the previous chapters, we deployed webstore namespaces and workloads in the hub cluster. Let's clean up these deployments from the hub cluster before redeploying them to the spoke cluster later.

### 1. Set labels workload_webstore = false and workloads = false

Currently, the webstore workload and its associated namespaces are deployed to the hub-cluster because it has the labels `workload_webstore=true` and `workloads = true`. Both the Namespace and Workload ApplicationSets check for the `workload_webstore=true` label, as shown below:

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='7-7'}
.
.
generators: - clusters:
selector:
matchLabels:
workload_webstore: 'true'  
 .
:::

To remove the webstore namespaces and workload from the hub-cluster, we will set `workload_webstore=false` and `workloads = false` on that cluster.

```bash
sed -i "s/workload_webstore = true/workload_webstore = false/g" ~/environment/hub/main.tf
sed -i "s/workloads = true/workloads = false/g" ~/environment/hub/main.tf
```

### 2 Terraform Apply

```bash
cd ~/environment/hub
terraform apply -auto-approve
```

### 3. Validate workload and namespace deletion

In the Argo CD UI, we should no longer see the Application resources for the webstore namespace and workload deploying to the hub-cluster. This confirms that Argo CD has detected the label changes and removed those components from the cluster.

![hub-workload-before-after](/static/images/hub-cluster-workload-before-after.png)

We can verify the namespace cleanup by checking existing namespaces. The webstore namespaces should no longer be present:

```bash
kubectl get ns --context hub
```
