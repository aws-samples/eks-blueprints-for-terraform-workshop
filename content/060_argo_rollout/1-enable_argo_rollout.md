---
title: 'Enable Argo Rollouts'
weight: 1
hidden: false
---

Earlier in the :link[Bootstrap ArgoCD]{href="/../030_provision_eks_cluster/6-bootstrap-argocd#add-kubernetes-addons-module-to-main.tf-with-only-argo-config"} section, we added the `kubernetes_addons` module. We enabled several add-ons using the EKS Blueprints for Terraform IaC. Argo Rollouts comes out of the box as an add-on, so all we need to do is enable it.

Go back to your Cloud9 environment and edit the `module/eks_cluster/main.tf` file, and under the `kubernetes_addons` module, add `enable_argo_rollouts = true`, to enable the add-on as shown below.

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

:::code{showCopyAction=false showLineNumbers=false language=hcl}
module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=blueprints-workshops/modules/kubernetes-addons"

... ommitted content for brevity ...

  enable_aws_load_balancer_controller  = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_argo_rollouts                 = true # <-- Add this line
}
:::

::alert[Don't forget to save the cloud9 file, as auto-save is not enabled by default.]{header="Important"}

Next, apply our changes via Terraform.

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform apply -auto-approve
```

## Validate Argo Rollouts Installation

One of the first things to check is the new namespace `argo-rollouts`

```bash
kubectl get all -n argo-rollouts
```

```
NAME                                 READY   STATUS    RESTARTS   AGE
pod/argo-rollouts-5656b86459-j9bjg   1/1     Running   0          3h38m
pod/argo-rollouts-5656b86459-rhthq   1/1     Running   0          3h38m

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argo-rollouts   2/2     2            2           3h38m

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/argo-rollouts-5656b86459   2         2         2       3h38m
```

The ArgoCD dashboard should also show you that the installation is green and all items are healthy.

::alert[For instructions on how to access the ArgoCD UI, take a look at our previous steps. :link[Bootstrap ArgoCD]{href="/030-provision-eks-cluster/04-configure-gitops/2-validate-argocd/"}]{header="Accessing the ArgoCD UI"}

![Argo Dashboard](/static/images/argo-rollouts-installed.png)
**FIGURE 2 - Argo Rollouts Installed Successfully**
