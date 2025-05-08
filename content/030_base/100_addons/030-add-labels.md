---
title: "Add Labels"
weight: 30
---


In this chapter, we’ll add labels  to the cluster. These will help to automate the installation and removal of add-ons in later chapters. 

In the Argo CD user interface, go to the hub cluster. The hub-cluster currently has some existing Labels and Annotations defined. These are added by GitOps Bridge.

![Hub Cluster Metadata](/static/images/hubcluster-initial-metadata.png)

> Labels can be used to find collections of objects that satisfy generator conditions. Annotations provide additional information.


### 1. Define addons variables

Define **enable_XXX_addons** boolean variables. These provide a simple way to control whether addons are installed or removed, that will be stored as labels.

Define addons_metadata variable as a list of key/value pairs that will be mapped to the secret annotations, and contain any important data that Argo CD can uses to configure the Applications.

Some values are commented and will be used later in the workshop.

For example, in the highlighted section below, We’ve defined the enable_cert_manager variable in the Terraform variables file. When it is set enable_cert_manager = true, Cert Manager is deployed; setting it to false removes it.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='6'}
cat <<'EOF' >> ~/environment/hub/main.tf

locals{
  tenant = "tenant1",
  fleet_member = "control-plane",
  aws_addons = {
    enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
    enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
    enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
    enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
    enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
    enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                          = try(var.addons.enable_external_dns, false)
    enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
    enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
    enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
    enable_karpenter                             = try(var.addons.enable_karpenter, false)
    enable_velero                                = try(var.addons.enable_velero, false)
    enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
    enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
    enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
    enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
    enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
    enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
    enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
    enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
    enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
    enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
    enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
    enable_aws_argocd                            = try(var.addons.enable_aws_argocd , false)
    enable_cw_prometheus                         = try(var.addons.enable_cw_prometheus, false)
    enable_cni_metrics_helper                    = try(var.addons.enable_cni_metrics_helper, false)
  }
  oss_addons = {
    enable_argocd                          = try(var.addons.enable_argocd, false)
    enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events                     = try(var.addons.enable_argo_events, false)
    enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
    enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
    enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
    enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
    enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
    enable_keda                            = try(var.addons.enable_keda, false)
    enable_kyverno                         = try(var.addons.enable_kyverno, false)
    enable_kyverno_policy_reporter         = try(var.addons.enable_kyverno_policy_reporter, false)
    enable_kyverno_policies                = try(var.addons.enable_kyverno_policies, false)
    enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
    enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_vpa                             = try(var.addons.enable_vpa, false)
  }

  labels = merge(
    local.aws_addons,
    local.oss_addons,
    { kubernetes_version = local.cluster_version },
    { aws_cluster_name = module.eks.cluster_name },
    { fleet_member = local.fleet_member },
    #{ workloads = true }
    #enablewebstore,{ workload_webstore = true }  
  )

}

EOF
:::
<!-- prettier-ignore-end -->

### 4. Update Labels and Annotations

We need to update the labels and annotations on the hub-cluster Cluster object. To do this, we will use the GitOps Bridge. The GitOps Bridge is configured to update labels and annotations on the specified cluster object.

```bash
sed -i "s/#enablelabel//g" ~/environment/hub/main.tf
```

The code provided above uncomments metadata and addons variables as highlighted below in `main.tf`. The values defined in the addons variable are assigned to Labels, while the metadata values are assigned to Annotations on the cluster object.

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=false showLineNumbers=false highlightLines='7-8'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    metadata = local.annotations
    addons = local.labels
}
:::
<!-- prettier-ignore-end -->

### 5. Terraform apply

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 6. Validate update to labels and addons

Goto to the **Settings > Clusters > hub-cluster** in the Argo CD dashboard. Examine the Hub-Cluster Cluster object. This will confirm that GitOps Bridge has successfully updated the Labels and Annotations.

![Hub Cluster Updated Metadata](/static/images/hubcluster-update-metadata.png)

Argo CD pulls labels and annotations for the cluster object from a kubernetes secret. We used gitops bridge to update labels and annotations for the secret.

You can check the Labels and annotations on the cluster secret:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o yaml
```

:::expand{header="Example of output"}

```
apiVersion: v1
data:
  config: ewogICJ0bHNDbGllbnRDb25maWciOiB7CiAgICAiaW5zZWN1cmUiOiBmYWxzZQogIH0KfQo=
  name: aHViLWNsdXN0ZXI=
  server: aHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3Zj
kind: Secret
metadata:
  annotations:
    addons_repo_basepath: ""
    addons_repo_path: bootstrap
    addons_repo_revision: HEAD
    addons_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-addons
    argocd_namespace: argocd
    aws_account_id: "012345678910"
    aws_cluster_name: hub-cluster
    aws_load_balancer_controller_namespace: kube-system
    aws_load_balancer_controller_service_account: aws-load-balancer-controller-sa
    aws_region: us-west-2
    aws_vpc_id: vpc-0281c90d8fb4ce6a2
    cluster_name: hub-cluster
    environment: control-plane
    external_secrets_namespace: external-secrets
    external_secrets_service_account: external-secrets-sa
    platform_repo_basepath: ""
    platform_repo_path: bootstrap
    platform_repo_revision: HEAD
    platform_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-platform
    workload_repo_basepath: ""
    workload_repo_path: ""
    workload_repo_revision: HEAD
    workload_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-apps
  creationTimestamp: "2024-10-07T21:40:44Z"
  labels:
    argocd.argoproj.io/secret-type: cluster
    aws_cluster_name: hub-cluster
    cluster_name: hub-cluster
    enable_argocd: "true"
    environment: control-plane
    fleet_member: control-plane
    kubernetes_version: "1.30"
    tenant: tenant1
    workloads: "true"
  name: hub-cluster
  namespace: argocd
  resourceVersion: "6865"
  uid: af0dfcb9-a034-4f2d-be9b-167eb78c830a
type: Opaque
```

:::

You can see now in the secret all the metadatas that has been configured by the **gitops_bridge_bootstrap** terraform module.
