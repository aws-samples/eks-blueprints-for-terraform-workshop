---
title: 'Test Hub Spoke Connectivity'
weight: 30
---


This chapter validates hub-spoke connectivity by checking for the AWS Load Balancer Controller installed on the spoke-staging cluster. In this workhshop, ArgoCD was configured to install addon by setting a label to true. The label enable_aws_load_balancer_controller=true installs the load balancer addon. This label was set during creation of the spoke cluster. Once hub-spoke connectivity between hub and spoke was established, ArgoCD installed the load balancer on the spoke by detecting this label had been set.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4'}
$ cat ~/environment/spoke/terraform.tfvars
...
addons = {
    enable_aws_load_balancer_controller = true
}
:::


You can check the label on the spoke-staging cluster: 

```bash
kubectl --context hub get secrets -n argocd spoke-staging -o json | jq ".metadata.labels" | grep load_balancer
```

The Terraform blueprint modules and gitops bridge set up an IAM role that gets assigned to the service account for the load balancer. This configures the necessary permissions for the load balancer to operate.

You can check the IAM role on the spoke-stagging annotations:

```bash
kubectl --context hub get secrets -n argocd spoke-staging -o json | jq ".metadata.annotations"  | grep load_balancer
```

The Argo CD dashboard should have the stagging load balancer addon.

![Stagging LB](/static/images/spoke-lb.png)

As you demonstrated in this chapter Argo CD allows enabling/disabling addons on a Kubernetes cluster by setting a boolean variable. When the variable is true, Terraform adds a label to the cluster resource telling Argo CD to install that addon.

It easy to deploy additional addons on different clusters!