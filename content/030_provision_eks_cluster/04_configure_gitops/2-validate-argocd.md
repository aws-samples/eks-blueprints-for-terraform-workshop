---
title: 'Validate ArgoCD deployment'
weight: 2
---

### Validate ArgoCD deployment

To validate that ArgoCD is now in our cluster, we can execute the following:

```bash
kubectl get all -n argocd
```

Wait about 2 minutes for the load balancer's creation and get its URL:

```bash
export ARGOCD_SERVER=`kubectl get svc argo-cd-argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
echo export ARGOCD_SERVER=\"$ARGOCD_SERVER\" >> ~/.bashrc
echo "https://$ARGOCD_SERVER"
```

Open a new browser and paste in the URL from the previous command. You will now see the ArgoCD UI.

::alert[Since ArgoCD UI exposed like this uses a self-signed certificate, you'll need to accept the security exception in your browser to access it.]{header="Important"}

### Query for admin password

Retrieve the generated secret for the ArgoCD UI admin password. 

::alert[Note: We could also instead create a Secret Manager's password for Argo with Terraform, see this [example](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/main/examples/blue-green-upgrade/environment/main.tf#L110-L125)]{header="Important"}

Retrieve the ArgoCD's password: 

```bash
ARGOCD_PWD=$(aws secretsmanager get-secret-value --secret-id argocd-admin-secret.eks-blueprint | jq -r '.SecretString')
echo export ARGOCD_PWD=\"$ARGOCD_PWD\" >> ~/.bashrc
echo "ArgoCD admin password: $ARGOCD_PWD"
```

## Login with the CLI

::alert[For the purpose of this lab, argocd CLI has been installed for you. You can learn more about installing the CLI tool by following the [instructions](https://argo-cd.readthedocs.io/en/stable/cli_installation/).]{header="Note"}

```bash
argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PWD --insecure
```

Then we can use the cli to interact with ArgoCD:

```bash
#List argocd Applications
argocd app list
```

```
NAME                                 CLUSTER                         NAMESPACE           PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS  REPO                                                       PATH                                  TARGET
argocd/addons                        https://kubernetes.default.svc                      default  Synced     Healthy  Auto-Prune  <none>      https://github.com/aws-samples/eks-blueprints-add-ons.git  chart                                 HEAD
argocd/aws-load-balancer-controller  https://kubernetes.default.svc  kube-system         default  Synced     Healthy  Auto-Prune  <none>      https://github.com/aws-samples/eks-blueprints-add-ons.git  add-ons/aws-load-balancer-controller  HEAD
argocd/metrics-server                https://kubernetes.default.svc  kube-system         default  Synced     Healthy  Auto-Prune  <none>      https://github.com/aws-samples/eks-blueprints-add-ons.git  add-ons/metrics-server                HEAD
```


## Login to the UI:

1. The username is **admin**.
2. The password is the result of the **Query for admin password** command above.

At this step, you should be able to see the Argo UI:

![ArgoCD UI](/static/images/argocdui.png)

> For any future [available add-ons](https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/) you wish to enable, simply follow the steps above by modifying the `kubernetes_addons` module within the `modules/eks_cluster/main.tf` file and terraform apply again in the `eks-blue` directory.

In the ArgoUI, you can see that we have several applications deployed:

- addons
  - aws-load-balancer-controller
  - aws_for_fluentbit
  - metrics_server

::alert[We declare six add-ons, but only two are listed in ArgoUI.]{header="Important" type="info"}

The EKS Blueprints can deploy Add-ons through [EKS managed add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) when they are available, which is the case for the EBS CSI driver, CoreDNS, KubeProxy and VPC CNI. In this case, it's not ArgoCD that managed them.

You can view them on the [EKS Console](https://console.aws.amazon.com/eks/home?#/clusters/eks-blueprint-blue?selectedTab=cluster-add-ons-tab)

![ArgoCD UI](/static/images/eks-managed-addons.png)

We will now work as members of **Team Riker** for the next module of the workshop.
