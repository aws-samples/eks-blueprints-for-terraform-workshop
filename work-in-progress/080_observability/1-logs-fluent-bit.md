---
title: 'Logs'
weight: 22
hidden: true
---

## Logging with FluentBit

Kubernetes supports different logging solutions but the most popular are FluentBit and Fluentd. Both are open-source log management tools that are designed to collect, enrich with filters and send your log data to any destination. Fluent Bit is a lightweight tool and is more suitable for resource-constrained environments and cloud-native use cases. See more info [here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-logs.html).   

In fact, we have already enabled FluentBit as part of previous steps. You can confirm it under `kubernetes_addons` section in your `main.tf` file:

```bash
enable_aws_for_fluentbit             = true
```

Above will enable EKS Data plane logs to be senr to AWS CloudWatch logs.

Fluent bit runs as a DaemonSet on each worker node. You can see its pods under `aws-for-fluent-bit` namespace. Run this command:

```bash
kubectl -n aws-for-fluent-bit get pods
```

Once FluentBit is enabled you can see `/eks-blueprint/worker-fluentbit-logs` LogGroup created in CloudWatch Logs.
This will include multiple log streams for all your containers running on the EKS cluster. 
Control plane logs will be listed under another `/aws/eks/eks-blueprint/cluster` log group in CloudWatch Logs.

To further customize your Addon configuration you should update `values.yaml` in your cloned repo [aws-for-fluent-bit](https://github.com/aws-samples/eks-blueprints-add-ons/blob/main/add-ons/aws-for-fluent-bit/values.yaml).

Any additional configuration added to your `values.yaml` file will be overwriting default chart’s upstream configuration that could be all found [here](https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit). 

To demonstrate this let’s overwrite default settings of `logStreamPrefix` which is set to `fluentbit-` by default in the downstream chart (see [here](https://github.com/aws/eks-charts/blob/master/stable/aws-for-fluent-bit/values.yaml#L85) ) with our environment name `dev-` for example. To do this we are going to add following line to our forked **eks-blueprints-add-ons** repo, under `add-ons/aws-for-fluent-bit/values.yaml` file:

```yaml
aws-for-fluent-bit:
  serviceAccount:
    create: false

  cloudWatch:
    logStreamPrefix: "dev-"    #  <-- Add this line
  firehose:

  kinesis:

  elasticsearch:

  tolerations:
    - operator: 'Exists'
```

After that you want to bump your Chart `version:` under Chart.yaml file to `0.1.1` and then push your changes.
Since **FluentBit Add-on** configuration is managed by **ArgoCD** we also want to restart `aws-for-fluent-bit` DaemonSet pods to pick up new settings. To do this, login to ArgoCD UI, click on **aws-for-fluent-bit** application, then click on the three dots next to the application **ds** (DaemonSet). Click on Restart option.

![argocd-fluentbit-ds-restart](/static/images/argocd-fb-restart.png)

Once restarted, new Log Stream Prefix `dev-` shows up next to each container Logs Stream shown below.

![cloudwatch-dev](/static/images/cloudwatch-dev.png)

FluentBit also supports streaming logs to additional destinations like Kinesis Data Firehose, Kinesis Data Streams or Amazon OpenSearch Service, etc. You can update a list of additional paths for logs to be collected using volume and volumeMount objects. See this [Helm Chart](https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit) for more details.