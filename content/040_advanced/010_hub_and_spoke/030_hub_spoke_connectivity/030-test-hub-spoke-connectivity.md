---
title: 'Test Hub Spoke Connectivity'
weight: 30
---

In this chapter, you will test hub-spoke connectivity by installing the AWS Load Balancer Controller on the spoke Kubernetes cluster. You set the `enable_aws_load_balancer_controller = true` on the spoke cluster's labels. As soon as the Hub's Argo CD notices this change in the label, it will install the load balancer controller on the spoke cluster.

### 1. Set spoke load balancer label

```bash
sed -i "s/enable_aws_load_balancer_controller = false/enable_aws_load_balancer_controller = true/g" ~/environment/spoke/terraform.tfvars
```

The code snippet above sets `enable_aws_load_balancer_controller = true`. The updated code is highlighted as follows:


:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4'}
$ cat ~/environment/spoke/terraform.tfvars
...
addons = {
    enable_aws_load_balancer_controller = true
}
:::

### 2. Apply Terraform

```bash
cd ~/environment/spoke
terraform apply --auto-approve
```

The Argo CD dashboard should have the stagging load balancer addon.

![Stagging LB](/static/images/spoke-lb.png)

As you demonstrated in this chapter Argo CD allows enabling/disabling addons on a Kubernetes cluster by setting a boolean variable. When the variable is true, Terraform adds a label to the cluster resource telling Argo CD to install that addon.