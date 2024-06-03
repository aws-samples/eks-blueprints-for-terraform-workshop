---
title: 'Watch Karpenter nodes'
weight: 4
---

### Step 5: Watch Workload on Karpenter's nodes as part of the Riker Application Team
### Step 5: Watch Workload on Karpenter's nodes as part of the Riker Application Team

::alert[We do modules of the workshop independently, and for this one, we assume that you have deleted the `rollout.yaml` from your workload application if you did the **Blue/Green Deployments with Argo Rollouts**]{header="Important"}
::alert[We do modules of the workshop independently, and for this one, we assume that you have deleted the `rollout.yaml` from your workload application if you did the **Blue/Green Deployments with Argo Rollouts**]{header="Important"}

Back to Cloud9 editor, we are going to scale our skiapp to 3 replicas:

```bash
# list the rollout
kubectl argo rollouts list rollouts -n team-riker
# Get detail on our ski-app rollouts
kubectl argo rollouts get rollout skiapp-rollout -n team-riker -w
```

Open a New Terminal and promote the Rollout (or do it with the UI)

```bash
kubectl argo rollouts promote skiapp-rollout -n team-riker --full
```

![](/static/images/rollout_promote_karpenter.png)

By promoting the new App this should leave only 3 pods for our application, and thoses pods should now be deployed on Karpenter instances.

::alert[Wait for Argo Rollout to promote new version and let the cluster with only 3 pode]{header="Important"}

![](/static/images/rollout_promote_karpenter_ok.png)

### Step 6: Visualize the Karpenter nodes

We are going to use a tool to dynamically see the nodes in our cluster: [eks-node-viewer](https://github.com/awslabs/eks-node-viewer). 
We are going to use a tool to dynamically see the nodes in our cluster: [eks-node-viewer](https://github.com/awslabs/eks-node-viewer). 

> This tool has already been installed in your Cloud9 environment. 

Open another terminal and execute:

```bash
eks-node-viewer -extra-labels karpenter.sh/provisioner-name,topology.kubernetes.io/zone
```

![](/static/images/eks-node-conf1-rollout1.png)

::alert[You should see 3 additional Karpenter node join the cluster!]{header="Important"}


### Step 7: Scale the Deployment manually so that we have 2 pods on each instance, one in each availability zone

#### 1. Scale skiapp to 6 replicas

```bash
kubectl scale deployment -n team-riker skiapp-deployment --replicas 6
```

> Look at your cluster and eks-node-viewer to see how it respond to the scaling

::::expand{header="What happened?"}
::::expand{header="What happened?"}
- it should add 3 **.large** nodes, one in each zone to fullfill our requirements (our topology spread constraints).
::::

#### 2. Now scale to 14 replicas

```bash
kubectl scale deployment -n team-riker skiapp-deployment --replicas 14
```

::::expand{header="What happened ?"}
- In first place, it add 3 bigger instances, one in each zone to fullfill our requirements (our topology spread constraints).
  ![](/static/images/eks-node-conf1-deploy-14-1.png)
- In a second time (several minutes), we can see that the Karpenter consolidation activate, and that it has removed the 3 smaller nodes, and move their pods on the bigger instance. 
  ![](/static/images/eks-node-conf1-deploy-14-2.png)
  
> This in another goal of Karpenter to infinitely try to save costs in your cluster.
::::

#### 3. Now scale to 20

```bash
kubectl scale deployment -n team-riker skiapp-deployment --replicas 20
```

::::expand{header="What happened ?"}
- Nothing

Why ?

```bash
kubectl describe replicaset -n team-riker | grep Error
```

```
 Warning  FailedCreate      9m4s                   replicaset-controller  Error creating: pods "skiapp-deployment-5b8f94fdc-6gm96" is forbidden: exceeded quota: team-riker, requested: pods=1, used: pods=15, limited: pods=15
``` 

- We have reach the namespace quotas for the number of pods

```bash
kubectl get quota -n team-riker
```
::::

#### 4. Increase quotas

You can increase the quotas by upgrading the values in `main.tf` and deploying again with Terraform.
You can increase the quotas by upgrading the values in `main.tf` and deploying again with Terraform.

In Cloud9:

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

And increase the allowed number of pods for our team-riker to 30
And increase the allowed number of pods for our team-riker to 30

```
...
  namespaces = {
    "team-${each.key}" = {
      labels = merge(
        {
          team = each.key
        },
        try(each.value.labels, {})
      )

      resource_quota = {
        hard = {
          "requests.cpu"    = "100",
          "requests.memory" = "20Gi",
          "limits.cpu"      = "200",
          "limits.memory"   = "50Gi",
          "pods"            = "30", #<-- increase number of pods
          "secrets"         = "10",
          "services"        = "20"
        }
...
  namespaces = {
    "team-${each.key}" = {
      labels = merge(
        {
          team = each.key
        },
        try(each.value.labels, {})
      )

      resource_quota = {
        hard = {
          "requests.cpu"    = "100",
          "requests.memory" = "20Gi",
          "limits.cpu"      = "200",
          "limits.memory"   = "50Gi",
          "pods"            = "30", #<-- increase number of pods
          "secrets"         = "10",
          "services"        = "20"
        }
      }
    }
...
```
...
```

Apply the change:
Apply the change:

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform apply --auto-approve
```

After some times, you should be able to have all pods deployed.

You may need to resynchronized the application

```bash
argocd app sync team-riker
```

![](/static/images/eks-node-scale29-rollout1.png)
