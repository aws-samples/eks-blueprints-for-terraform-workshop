---
title: 'Test Hub Spoke Connectivity'
weight: 30
---

In this chapter, you will test hub-spoke connectivity by checking the installation of the AWS Load Balancer Controller on the spoke Kubernetes cluster. We have configured the `enable_aws_load_balancer_controller = true` on the spoke cluster's labels. As soon as the Hub's Argo CD has connectivity, it can reconcile the labels and install associated addons.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4'}
$ cat ~/environment/spoke/terraform.tfvars
...
addons = {
    enable_aws_load_balancer_controller = true
}
:::

In this contexte, the eks-blueprints-addons module from spoke-staging, will create necessary AWS resources for the load balancer controller to work, then it will update the spoke-staging secret in the hub-cluster with the label to activate the addon, and also provide additional metadatas like the IAM role to be used by the load balancer controller. 


You can check the label with: 

```bash
kubectl --context hub get secrets -n argocd spoke-staging -o json | jq ".metadata.labels" | grep load_balancer
```

and the annotations with:

```bash
kubectl --context hub get secrets -n argocd spoke-staging -o json | jq ".metadata.annotations"  | grep load_balancer
```

From then, Argo CD in the hub-cluster will trigger some deployments using the annoations in the secret to configure the addon, targeting the spoke-staging cluster, and installing the load balancer controller addon.


The Argo CD dashboard should have the stagging load balancer addon.

![Stagging LB](/static/images/spoke-lb.png)

As you demonstrated in this chapter Argo CD allows enabling/disabling addons on a Kubernetes cluster by setting a boolean variable. When the variable is true, Terraform adds a label to the cluster resource telling Argo CD to install that addon.

It easy to deploy additional addons on different clusters!