---
title: 'Create a Green cluster in N+1'
weight: 3
---

We have set the base for our blue/green cluster migration for our skiapp application.

Now we are going to create an EKS green cluster with version N+1 which is 1.26 in our case.

## Create Green cluster

Within your Cloud9 IDE, duplicate the code of the blue cluster to green, and remove the existing Terraform state to start fresh:

```bash
cp -r ~/environment/eks-blueprint/eks-blue ~/environment/eks-blueprint/eks-green
rm -rf ~/environment/eks-blueprint/eks-green/.terraform*
rm -rf ~/environment/eks-blueprint/eks-green/terraform.tfstate*
```
Now edit the main.tf to change the cluster service name and version:

```bash
sed -i "s/^\(\s*\)service_name\s*=\s*\"blue\"/\1service_name    = \"green\"/" ~/environment/eks-blueprint/eks-green/main.tf
sed -i "s/^\(\s*\)cluster_version\s*=\s*\"1.25\"/\1cluster_version = \"1.26\"/" ~/environment/eks-blueprint/eks-green/main.tf
```

Install the new cluster with Terraform

```bash
cd ~/environment/eks-blueprint/eks-green
terraform init
terraform apply --auto-approve
```

> Take a break. This will take 20 minutes.

## Connecting to the green cluster

Once the Green terraform stack ends, it should create the same cluster we have for blue, but in version 1.26 of Kubernetes.
Because we are using GitOps with ArgoCD, all our applications should be automatically deployed in the new cluster with no more action on our part.

As we did with the blue cluster, we can take the output from the `terraform output` to connect to the cluster.
In order to be able to access both clusters, I recommend opening a second terminal and creating a dedicated kubeconfig file instead of the default `~/.kube/config` so that we can access different clusters in our different terminals.

Connect to the green cluster:

```bash
cd ~/environment/eks-blueprint/eks-green
export KUBECONFIG=$PWD/kubeconfig.yaml
aws eks --region $AWS_REGION update-kubeconfig --name eks-blueprint-green
```

Now you can see what is deployed in our green cluster:

```bash
kubectl get pods -A
```

The green cluster has its own ArgoCD deployed, with the same password as the one we already deployed, so you can connect to it the same way you did with the blue one, [see Validate ArgoCD deployment](/030-provision-eks-cluster/04-configure-gitops/2-validate-argocd).

## Validate the Application

As previously explain, you access your application from the new cluster preview of your application in each cluster with the default ingress load balancer: 

```bash
curl -s http://$(kubectl get ing -n team-riker skiapp-ingress-nginx -o json | \
   jq ".status.loadBalancer.ingress[0].hostname" -r)
```

or by clicking in the ArgoCD UI:

![](/static/images/skiapp-ingress-nginx.png)


In order to be able to know from which cluster the skiapp has been served, we have added this information at the bottom of the page:

![](/static/images/eks-blueprint-blue.png)

We can also test it with the command:

```bash
curl -s http://$(kubectl get ing -n team-riker skiapp-ingress-nginx -o json | \
   jq ".status.loadBalancer.ingress[0].hostname" -r) | grep cluster
```

It should output eks-blueprint-blue on the blue cluster and eks-blueprint-green on the green cluster.

```
                  <p class="lead smaller-paragraph">Running on the EKS cluster: <b>eks-blueprint-pink</b></p>
```                  