---
title : "Accessing the cluster"
weight : 3
---

When finished, your Terraform outputs should look something like: 

:::code{showCopyAction=false language=hcl}
outputs:

configure_kubectl = "aws eks --region eu-west-1 update-kubeconfig --name eks-blueprint-blue"
eks_cluster_id = "eks-blueprint-blue"
:::

You can now connect to your EKS cluster using the previous command:

```bash
aws eks --region $AWS_REGION update-kubeconfig --name eks-blueprint-blue
```

>**update-kubeconfig** configures kubectl so that you can connect to an Amazon EKS cluster.

>**kubectl** is a command-line tool used for communication with a Kubernetes cluster's control-plane, using the Kubernetes API.

You can list the pods in all namespaces with: 

```bash
kubectl get pods -A
```

```
NAMESPACE     NAME                       READY   STATUS    RESTARTS     AGE
kube-system   aws-node-h66pd             1/1     Running   1 (9h ago)   15h
kube-system   aws-node-qdtjx             1/1     Running   1 (9h ago)   15h
kube-system   aws-node-wdbsg             1/1     Running   1 (9h ago)   15h
kube-system   coredns-6bc4667bcc-sgbm2   1/1     Running   1 (9h ago)   16h
kube-system   coredns-6bc4667bcc-vkchc   1/1     Running   1 (9h ago)   16h
kube-system   kube-proxy-4csbd           1/1     Running   1 (9h ago)   15h
kube-system   kube-proxy-779xp           1/1     Running   1 (9h ago)   15h
kube-system   kube-proxy-dppr2           1/1     Running   1 (9h ago)   15h
```

::alert[You just deployed your first EKS cluster with Terraform.]{header="Congratulation!"}

At this stage, we just installed a basic EKS cluster with the minimal addon required to work:

- VPC CNI driver, so we get AWS VPC support for our pods.
- CoreDNS for internal Domain Name resolution.
- Kube-proxy to allow the usage of Kubernetes services.

This is not sufficient to work in AWS; we are going to see how we can improve our deployments in the next sections.


<!--
```bash
cat > versions.tf << 'EOF'

EOF
```

```bash
cat > versions.tf << 'EOF'

EOF
```
-->