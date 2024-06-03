---
title: 'Connect with teams'
weight: 56
---

In the previous step, we created the EKS cluster, and the module outputs the `kubeconfig` information, which we can use to connect to the cluster.
We can see an example of how we can use those instructions.

### Step 1: Connect to the cluster as Team Riker

At the time we created the EKS cluster, the current identity you are using in the lab was automatically added to the Application team-riker Team thanks to the `users` parameter. 

::alert[We also added the role provided by the `eks_admin_role_name` variable we provided; this is an example to show you how you can adapt to your own organization.]{header="Important"}



If you added additional AWS IAM Role ARNs during the definition of Team-Riker, then you can safely assume that role as it was added to the auth configmap of the cluster.

If you want to get the command to configure `kubectl` for each team, you can add it to the output to retrieve it.

Let's retrieve our connection commands: 

```bash
# Apply changes to provision the Platform Team
terraform output
```

You will see the `kubectl` configuration command to share with members of **Team Riker**, Copy the `aws eks update-kubeconfig ...` command portion of the output that corresponds to **Team Riker**, This would be something similar to: 

```
aws eks --region eu-west-1 update-kubeconfig --name eks-blueprint-blue  --role-arn arn:aws:iam::798082067117:role/team-riker-20230531130037207700000002
```

::alert[Copy the command from your own `terraform output` not the example above. The region, account's ID values, and role name should be different.]{header="Important" type="info"}

You can also see which entity can execute the previous command by looking at the Trust Relationship of the team-riker role: 

```bash
aws iam get-role --role-name team-riker-20230531130037207700000002
```

> --> change the Role name with yours



Now you can execute `kubectl` CLI commands in the **team-riker** namespace.

Let's see if we can do the same commands as previously:

```bash
# list nodes ? yes
kubectl get nodes
# List pods in team-riker namespace ? yes
kubectl get pods -n team-riker
# list all pods in all namespaces ? no
kubectl get pods -A
# can i create pods in kube-system namespace ? no
kubectl auth can-i create pods --namespace kube-system
# list service accounts in team-riker namespace ? yes
kubectl get sa -n team-riker
# list service accounts in default namespace ? no
kubectl get sa -n default
# can i create pods in team-riker namespace ? no (readonly)
kubectl auth can-i create pods --namespace team-riker
# can i list pods in team-riker namespace ? yes
kubectl auth can-i list pods --namespace team-riker
```

As expected, you can see here that our team-riker Role, has read-only rights in the cluster, but only in the team-riker namespace.

You can always see the objects in your namespace, like:

```bash
kubectl get resourcequotas -n team-riker
```

```
NAME         AGE   REQUEST                                                                                    LIMIT
team-riker   80m   pods: 0/100, requests.cpu: 0/100, requests.memory: 0/20Gi, secrets: 0/10, services: 0/20   limits.cpu: 0/200, limits.memory: 0/50Gi
```

It is best practice to not create Kubernetes objects with kubectl directly but to rely on continuous deployment tools. We are going to see in our next exercise how we can leverage ArgoCD for that purpose!

### Connect with other teams

Take some time to authenticate with the other teams from the output and see what you can do in the cluster.

> This is how you will be able to provide different access to different namespaces for your teams in your shared EKS cluster.

### Work with the Platform Team for the workshop

OK, now configure `kubectl` back to the current creator of the EKS cluster, because we need admin access for the rest of the workshop:

```bash
aws eks --region $AWS_REGION update-kubeconfig --name eks-blueprint-blue
```

In the next section, we are going to bootstrap a [GitOps](https://www.gitops.tech) tool named [ArgoCD](https://argoproj.github.io/cd/) that we will use to manage EKS add-ons and workload deployment inside our EKS cluster.

Check that you can list pods in all namespaces: 

```bash
kgp -A
```

```
NAMESPACE     NAME                       READY   STATUS    RESTARTS      AGE
kube-system   aws-node-h66pd             1/1     Running   1 (14h ago)   21h
kube-system   aws-node-qdtjx             1/1     Running   1 (14h ago)   21h
kube-system   aws-node-wdbsg             1/1     Running   1 (14h ago)   21h
kube-system   coredns-6bc4667bcc-sgbm2   1/1     Running   1 (14h ago)   21h
kube-system   coredns-6bc4667bcc-vkchc   1/1     Running   1 (14h ago)   21h
kube-system   kube-proxy-4csbd           1/1     Running   1 (14h ago)   21h
kube-system   kube-proxy-779xp           1/1     Running   1 (14h ago)   21h
kube-system   kube-proxy-dppr2           1/1     Running   1 (14h ago)   21h
```

