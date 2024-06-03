---
title: 'Migrate skiapp from blue to green cluster'
weight: 3
---

At this stage, we have 2 identical EKS clusters bootstrapped with the same ArgoCD applications, but in different versions.

> 100% of requests coming from ALB to our skiapp request are routed to the blue cluster; the green cluster is not live yet.


![](/static/images/blue-green-alb-tg-vpc.png)


In a terminal, let's create a loop to see which server is serving our skiapp, and keep it running while we shift traffic:

```bash
export ALB_DNS=`aws elbv2 describe-load-balancers --names eks-blueprint-alb --query 'LoadBalancers[0].DNSName' --output text`
for x in `seq 0 100` ; do  curl -s $ALB_DNS | grep cluster ; sleep 2 ; done
```

## Load balance application traffic across clusters

Let's activate 50% requests on both clusters. For that, we are going to update the Load Balancer weigths in the **environment** stack.

Let's open the environment/main/tf file:

```bash
c9 open ~/environment/eks-blueprint/environment/main.tf
```

Locate the part of the listener where we defined the routing weights and update it to 50/50%.

```
  http_tcp_listener_rules = [
    {
      actions = [{
        type = "weighted-forward"
        target_groups = [
          {
            target_group_index = 0
            weight             = 50 #<- Update here
          },
          {
            target_group_index = 1
            weight             = 50 #<- Update here
          }
        ]
```

Apply the change: 

```bash
cd ~/environment/eks-blueprint/environment/
tfy
```

Once applied, you should start to see random requests targeting both clusters:

```
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-green</b></p>
                  <p class="lead smaller-paragraph">Running on EKS cluster: <b>eks-blueprint-blue</b></p>
```

You can do progressive Canary deployment from blue to green clusters, and in the end, you can migrate 100% of the traffic to the green cluster: 

```
  http_tcp_listener_rules = [
    {
      actions = [{
        type = "weighted-forward"
        target_groups = [
          {
            target_group_index = 0
            weight             = 0 #<- Update here
          },
          {
            target_group_index = 1
            weight             = 100 #<- Update here
          }
        ]
```

At this step, the blue cluster is not used anymore. You can keep it a little in case you need to rollback some applications, or you can just delete the blue cluster (see [cleanup section](/090-cleanup)).

Later, if you need to create a new cluster, you will re-create a blue cluster with the associated new EKS version and migrate again from green to the new blue cluster.