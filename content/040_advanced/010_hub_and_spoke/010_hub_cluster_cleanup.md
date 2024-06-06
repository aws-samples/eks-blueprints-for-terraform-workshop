---
title: '[Optional] ArgoCD Hub Cluster Cleanup'
weight: 10
---

In ArgoCD hub-spoke deployment architecture, hub is dedicated to only ArgoCD. In the previous chapter you have deployed webstore namespace and workload in the hub cluster.
In this chapter you can undeploy webstore namespace and workload, from the hub cluster, we will redeploy them later in the spoke cluster.

### 1. Set label workload_webstore = false and workloads = false

The webstore workload and its associated namespaces are deployed to the hub-cluster. This is because the hub-cluster has the label `workload_webstore=true` and `workloads = true`. 
Both the Namespace and Workload ApplicationSets have a condition specifying `workload_webstore=true`, as shown below:

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='7-7'}
    .
    .
        generators:
          - clusters:
              selector:
                matchLabels:
                  workload_webstore: 'true'   
  .
:::

Also set `workloads = false` to remove namespace application.

To undeploy the webstore namespaces and workload from the hub-cluster, you can set `workload_webstore=false` on that cluster. 

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

In the ArgoCD UI, you should see that the Application resources for the webstore namespace and workload no longer show any deployments to the hub-cluster. This verifies that ArgoCD has detected the label change and undeployed those components from that cluster as expected.

![hub-workload-before-after](/static/images/hub-cluster-workload-before-after.png)

You can check existing namespaces. It should not show any webstore namespaces.

```bash
kubectl get ns --context hub
```


