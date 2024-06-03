---
title: 'Tracing'
weight: 22
hidden: true
---

# Distributed Tracing with ADOT and X-Ray

We're using a very specific OpenTelemetry Agent - [AWS Distro for OpenTelemetry (ADOT)](https://aws.amazon.com/otel/), which is an AWS distribution of the OpenTelemetry project. It provides an easy way to get started with OpenTelemetry on AWS and includes a set of pre-built packages and configurations. 

To setup the tracing delivery from our cluster to X-Ray we need to install ADOT (operator), Collector (custom resource), and instrument the app. Basically, ADOT Operator assumes we'll have multiple collectors for different use cases. 

Complete setup with EKS, ADOT, and X-Ray looks like this:

![X-Ray tracing arch](/static/images/c06-tracing-arch.png)

## Install ADOT add-on

We bootstrap our cluster with ADOT add-on which is availabe as an option in out Blueprint Terraform module. For that we just need to add the next snippet to our add-ons section:

```
  enable_amazon_eks_adot               = true
  amazon_eks_adot_config = {
    most_recent        = true
    kubernetes_version = module.eks_blueprints.eks_cluster_version
    resolve_conflicts  = "OVERWRITE"
  }
```

next step is to setup [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for the collector to be able to export the traces to XRay. In the end of our main.tf file add irsa module:

```
module "adot_collector_irsa_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.21.0/modules/irsa"

  create_kubernetes_namespace       = true
  create_kubernetes_service_account = true
  kubernetes_namespace              = "aws-otel-eks"
  kubernetes_service_account        = "aws-otel-collector"
  irsa_iam_policies                 = ["arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"]
  eks_cluster_id                    = module.eks_blueprints.eks_cluster_id
  eks_oidc_provider_arn             = module.eks_blueprints.eks_oidc_provider_arn
}
```

then review the changes and apply to the cluster

```
terraform apply
```

As a result you should have a new namespace created (named `opentelemetry-operator-system`). Find it in the list of namespaces in the cluster:

```
kubectl get ns
```

and make sure the controller is up and running:

```
kubectl -n opentelemetry-operator-system get po
```

## Create a Collector

Once ADOT is done we create a Custom Resource called 'Collector'. Its job is to accept spans from the App and export them to our X-Ray storage.

As with any Operator, we need additional CustomResource to configure the controller. Here we install a CustomResource named `OpenTelemetryCollector`. The definition of the resource:

```bash
cat > adot-xray.yaml <<EOF
---
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: observability
  namespace: aws-otel-eks
spec:
  mode: deployment
  serviceAccount: aws-otel-collector
  env:
    - name: CLUSTER_NAME
      value: eks-blueprint
  ports:
    - name: otel-grpc
      port: 4317
      protocol: TCP
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317

    processors:
      batch/traces:
        timeout: 1s
        send_batch_size: 50

    exporters:
      awsxray:

    service:
      pipelines:
        traces:
          receivers: [otlp]
          exporters: [awsxray]
EOF
```

Before apply let's describe what this definition means to us. First thing to note is that the  resource will be installed in `aws-otel-eks` namespace. In the `spec` we configure the collector to be aware of the cluster name (we'll need the traces to be distinguishable in the XRay UI), udp port for the receiver, and, finally, OpenTelemetry config. The config is canonical OTel config file where we have receivers,processors,exporters, and the service. Feel free to dive into the [detailed docs](https://opentelemetry.io/docs/collector/configuration/) on that matter. The most important thing to note is that our collector accepts `otel` traces and exports them to `xray`.

```
kubectl describe ns -l kubernetes.io/metadata.name=aws-otel-eks
```

and the collector pod in this namespace. Verify the pod is running with the command below:

```
kubectl -n aws-otel-eks get po
```

With ADOT Operator and Collector in place we can deploy our instrumented App and make it send spans to the collector.


# Enabling Tracing for the Skiapp

Throughout this workshop, we've been using the skiapp and have deployed it with a Load Balancer. Now, we are going to enable it for tracing and logging. Our Skiapp is already instrumented and the feature can be easily turned on with single environment variable `ENABLE_TRACING: true`.

By that point we already have the app deployed by ArgoCD. Since our git repo is the source of truth for deployments let's make the changes there and let ArgoCD redeploy the changes for us.In the `teams/team-riker/dev/templates/alb-skiapp/deployment.yaml` file add environment variable to the mainfest. It  should be looking like this:

```
...removed for clarity...
  template:
    metadata:
      labels:
        app: skiapp
    spec:
      containers:
        - name: skiapp
          image: sharepointoscar/skiapp:v3
          env:
            - name: ENABLE_TRACING
              value: 'true'
          ports:
            - containerPort: 8080
...removed for clarity...
```

and commit + push the changes to your github repo. After some grace period the ArgoCD controller picks up the changed and redeploys the Skiapp deployment. You can watch for this with `kubectl -n team-riker get po -w`. 

Once the deployment upgraded and new pod is up and running just open the Skiapp UI again and verify the traces are visible in X-Ray UI.

In your AWS account find X-Ray service and click **Traces**

![X-Ray console](/static/images/c06-tracing-xray-console.png)

Every request should be a separate trace in the list. 

![X-Ray traces](/static/images/c06-tracing-xray-traces.png)

When click on a trace X-Ray displays additional details of the request including HTTP info. Feel free to familiarize yourself wit the available context and metadata.