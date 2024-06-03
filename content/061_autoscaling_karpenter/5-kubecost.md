---
title: '[Optional] Cost optimization with Kubecost'
weight: 5
---

### Step 7: Improve cluster cost by fine-tuning our application

We have the ability to add more capacity to our cluster in order to scale our workloads, and Karpenter ensures an optimal balance between instances and cost. However, from a cost perspective, it should not be the only way to meet our needs. We also should look to optimize our cluster resource usage by having better configuration of the workloads we deploy.

The development team is responsible for configuring their applications for EKS. They must properly define the resources and limits that their applications need in order to be deployed in the cluster. Then it is the responsibility of the Kube scheduler and Karpenter to provide the necessary capacity according to the allowed quotas for our team.

If our Team-Riker now wants to be able to deploy more pods, but can no longer increase their quotas, they should optimize their application manifests.

Knowing what value needs to be set for resource requests and limits can be difficult, especially when running hundreds of applications.

[AWS and Kubecost](https://aws.amazon.com/blogs/containers/aws-and-kubecost-collaborate-to-deliver-cost-monitoring-for-eks-customers/) collaborate to deliver cost monitoring for EKS customers, and Kubecost can also be used to retrieve cost-optimization recommendations on resource requests and limit configuration for workloads. Let's see how this can work.

#### Install Kubecost 

Kubecost provides real-time cost visibility and insights for teams using Kubernetes, helping you continuously reduce your cloud costs. Amazon EKS supports Kubecost, which you can use to monitor your costs broken down by Kubernetes resources including pods, nodes, namespaces, and labels.

Go back to your `main.tf` and enable the Kubecost add-on and redeploy your Terraform:

```bash
c9 open ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

```
module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=blueprints-workshops/modules/kubernetes-addons"

...

  enable_aws_load_balancer_controller  = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_argo_rollouts                 = true 
  enable_karpenter                     = true 
  enable_karpenter                     = true                                        
  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name 
  karpenter_enable_spot_termination_handling = true 
  enable_kubecost                      = true  #  <-- Add this line 
}
```  

> Save the file :)

#### Deploy the Kubecost Add-On

Run Terraform to deploy the Kubecost add-on:

```bash
cd ~/environment/eks-blueprint/eks-blue
terraform apply --auto-approve
```


#### Accessing the KubeCost UI

Enable the port-forward so that we can access the Kubecost UI:

```bash
kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090:9090
```

enable some iptables to access the UI

```bash
sudo iptables -t nat -I OUTPUT -o lo -p tcp --dport 8080 -j REDIRECT --to-port 9090
sudo iptables -I INPUT -p tcp --dport 9090
sudo iptables -I INPUT -p tcp --dport 8080
```

- Access the `Tools -> Preview -> Preview Running Application` 
- You should have access to the KubeCost UI

#### Investigating Kubecost

We know we want to see if we can optimize our skiapp workload:
1. Click on **Savings** in the left menu.
2. Click on **Right-size your container requests**.
3. We can see a table where there are some recommendations, like the following: focus on our skiapp application.

![](/static/images/kubecost-skiapp.png)

> We can see a recommendation of 10m for CPU requests and 43Mi for memory requests

With that, go back to your workload definition repository in codespace, and: 
1. Edit the deployment.yaml file to change our pod resources.
2. Update the replicas to 20 (our actual live configuration).
 
::alert[As we have updated the number of replicas from the cli, also put back the number of replicas in the file]{header="Important"}

  ```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: skiapp-deployment
  namespace: team-riker
spec:
  selector:
    matchLabels:
      app: skiapp
  replicas: 20 #<-- Update replicas
  ...
          resources:
            requests:
              memory: '34Mi' # <-- Update memory request
              cpu: '10m' # <-- Update cpu request
            limits:
              memory: '128Mi'
              cpu: '1'  
```

3. Commit and push your changes, and let ArgoCD synchronize them with the cluster

```bash
git add .
git commit -m "improve skiapp resources for cost; and change replicas to 20"
git push
```

::::expand{header="What happened?"}
- Each of the pods now take less place on the Karpenter nodes.
- After few minutes, Karpenter consolidation will activate to optimize your cluster costs. 
  - Karpenter may start smaller nodes
  - Karpenter may terminate unnecessary nodes
::::

1. Karpenter consolidation will start, as new pods need fewer resources with the new configuration

You can see the logs of Karpenter

```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f | grep consolidation
```

![](/static/images/karpenter-consolidation.png)

6. After some time, all the nodes should have changed to lower-priced ones.

![](/static/images/karpenter-consolidation-2.png)

::alert[In our configuration, we limited the EC2 instances category to be 'm' and 'c', but without this limitation, Karpenter could even choose cheaper instances.]{header="Important"}

## Conclusion

By leveraging Kubecost, we were able to right size our applications. Thanks to the consolidation of Karpenter this directly reflects by optimizing our compute and decreasing our cluster costs.