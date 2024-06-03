---
title: '[Optional] Cost optimization with Spot'
weight: 6
---

### Step 5: Improve cluster cost by leveraging EC2 Spot Instances

#### Switch our skiapp to uses Spot instances with Karpenter

Now, in order to reduce even more of our costs, let's enable Spot instances for our skiapp application.

1. Edit the `karpenter.yaml` file in your workload repository, and edit the capacity-type line:

```
    - key: karpenter.sh/capacity-type
      operator: In
      values: ['on-demand', 'spot']
```

2. Add the file and commit the change

```bash
git add .
git commit -m "add Spot on the Karpenter provisioner"
git push
```

Watch Karpenter consolidation
We can see Karpenter creating new Spot instances and Cordoned an on-demand one to be replaced
![](/static/images/karpenter-consolidation_spot1.png)


```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f | grep consolidation
```

```
2023-06-05T17:13:09.532Z        INFO    controller.deprovisioning       deprovisioning via consolidation replace, terminating 1 nodes ip-10-0-46-90.eu-west-1.compute.internal/m5a.large/on-demand and replacing with spot node from types m5ad.large, m3.large, m6idn.large, m6a.large, m6id.large and 14 other(s)       {"commit": "c4a4efd-dirty"}
```

After some time, Karpenter has replaced our 3 on-demand instances with Spot instances.

![](/static/images/karpenter-consolidation_spot2.png)
- Our cluster costs have dropped from 755,55$/month to 608,82$/month when right-sizing our skiapp Pod Spec
- The cluster cost then dropped to 498$/month when relying on spot instances for our ski app.


::alert[For this exercise, we still created a managed node group of 3 instances of type m5.xlarge, which we see are really underutilized. So we can further improve our cluster costs by either changing the size of those nodes or moving the pods on it to Fargate]{header="Important"}

#### Spot interruptions in action

As you may know, Spot instances are spare capacity and may be taken back by AWS at any time with a 2-minutes window. For stateless container workloads, this is not a big deal as Kubernetes can always reschedule pods to other available instances, and Karpenter has integration to detect Spot termination signals through an SQS queue and will then drain the impacted instances

##### How do Spot Interruptions work?

When users request On-Demand Instances from a pool to the point that the pool is depleted, the system will select a set of Spot Instances from the pool to be terminated. A Spot Instance Pool is a set of unused EC2 instances with the same instance type (for example, m5.large), operating system, Availability Zone, and network platform. The Spot Instance is sent an interruption notice two minutes ahead to gracefully wrap up things.

Amazon EC2 terminates your Spot Instance when Amazon EC2 needs the capacity back (or the Spot price exceeds the maximum price for your request). More recently, Spot instances also support instance rebalance recommendations. Amazon EC2 emits an instance rebalance recommendation signal to notify you that a Spot Instance is at an elevated risk of interruption. This signal gives you the opportunity to proactively rebalance your workloads across existing or new Spot Instances without having to wait for the two-minute Spot Instance interruption notice.

##### Karpenter and Spot Interruptions

Karpenter natively handles Spot Interruption Notifications by consuming events from an SQS queue that is populated with Spot Interruption Notifications via EventBridge. All of the infrastructure is setup by Karpenter’s Terraform module, which was applied previously. When Karpenter receives a Spot Interruption Notification, it will gracefully drain the interrupted node, and any running pods will need to quickly be rescheduled, so Karpenter will provision a new node.

##### Simulate Spot interruption

With AWS, we can simulate Spot Interruptions using AWS FIS

1. Go to the AWS console and select **EC2**, then click on **Instances/Spot Requests**.
2. Select a Spot request that corresponds to our EKS cluster and click on **Actions / Initiate Interruption**.
3. This brings you to the **AWS FIS** console.
  - Keep the *Default role* and click on **Initiate interruption**.

![](/static/images/spot_fis.png)

In reaction to the interruption, we should see Karpenter drain pods on the targeted instance and then launch a new one to fulfill our pending pods.

You can check Karpenter logs that have detected the interruption:

```bash
kubectl logs -n karpenter deployment/karpenter -f
```

Once the Spot interruption is send to your instance, you should see Karpenter trigger it, drain the impacted instance, and launch a replacement one automatically:

```
2023-06-05T18:18:52.417Z        DEBUG   controller.interruption removing offering from offerings        {"commit": "c4a4efd-dirty", "queue": "karpenter-eks-blueprint-blue", "messageKind": "SpotInterruptionKind", "node": "ip-10-0-51-122.eu-west-1.compute.internal", "action": "CordonAndDrain", "unavailable-reason": "SpotInterruptionKind", "instance-type": "m5.large", "zone": "eu-west-1c", "capacity-type": "spot", "unavailable-offerings-ttl": "3m0s"}
2023-06-05T18:18:52.424Z        INFO    controller.interruption deleted node from interruption message  {"commit": "c4a4efd-dirty", "queue": "karpenter-eks-blueprint-blue", "messageKind": "SpotInterruptionKind", "node": "ip-10-0-51-122.eu-west-1.compute.internal", "action": "CordonAndDrain"}
2023-06-05T18:18:52.469Z        INFO    controller.termination  cordoned node   {"commit": "c4a4efd-dirty", "node": "ip-10-0-51-122.eu-west-1.compute.internal"}
2023-06-05T18:18:53.944Z        INFO    controller.provisioner  found provisionable pod(s)      {"commit": "c4a4efd-dirty", "pods": 8}
2023-06-05T18:18:53.944Z        INFO    controller.provisioner  computed new node(s) to fit pod(s)      {"commit": "c4a4efd-dirty", "newNodes": 1, "pods": 7}
2023-06-05T18:18:53.944Z        INFO    controller.provisioner  computed 1 unready node(s) will fit 1 pod(s)    {"commit": "c4a4efd-dirty"}
2023-06-05T18:18:53.944Z        INFO    controller.provisioner  launching node with 7 pods requesting {"cpu":"515m","memory":"424Mi","pods":"12"} from types c6in.xlarge, c5d.4xlarge, m5d.2xlarge, c6in.4xlarge, m6i.4xlarge and 108 other(s)    {"commit": "c4a4efd-dirty", "provisioner": "default"}
2023-06-05T18:18:54.296Z        DEBUG   controller.provisioner.cloudprovider    created launch template {"commit": "c4a4efd-dirty", "provisioner": "default", "launch-template-name": "Karpenter-eks-blueprint-blue-6627663970647983096", "launch-template-id": "lt-0a014844c3526d100"}
2023-06-05T18:18:55.209Z        INFO    controller.termination  deleted node    {"commit": "c4a4efd-dirty", "node": "ip-10-0-51-122.eu-west-1.compute.internal"}
2023-06-05T18:18:56.397Z        INFO    controller.provisioner.cloudprovider    launched new instance   {"commit": "c4a4efd-dirty", "provisioner": "default", "launched-instance": "i-049c7c546050069e7", "hostname": "ip-10-0-51-124.eu-west-1.compute.internal", "type": "m6i.large", "zone": "eu-west-1c", "capacity-type": "spot"}
```
