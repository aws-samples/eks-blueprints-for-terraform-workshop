---
title: 'Metrics'
weight: 22
hidden: true
---

## Metrics with Kube Prometheus Stack

Another `add-on` that is available on EKS Blueprints for Terraform is Kube Prometheus Stack. This particular `add-on` when enabled installs Prometheus instance, Prometheus operator, kube-state-metrics, node-exporter, alertmanager as well as Grafana instance with preconfigured dashboards. This stack is meant for cluster monitoring, so it is pre-configured to collect metrics from all Kubernetes components. In addition to that it delivers a default set of dashboards and alerting rules.
More on [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

Add following configuration under `kubernetes_addons` section in your `main.tf` file:

```bash
module "kubernetes_addons" {
source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.22.0/modules/kubernetes-addons"
... ommitted content for brevity ...

  enable_aws_load_balancer_controller  = true
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_argo_rollouts                 = true 
  enable_kube_prometheus_stack         = true # <-- Add this line

... ommitted content for brevity ...
}
```

And, apply changes: 

```bash
# Always a good practice to use a dry-run command
terraform plan
```
```bash
# Apply changes to provision the Platform Team
terraform apply -auto-approve
```

After successful installation you can see all Kube Prometheus Stack pods created and running under `kube-prometheus-stack` namespace:

```bash
$ kubectl -n kube-prometheus-stack get pods
NAME                                                        READY   STATUS    RESTARTS   AGE
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running   0          32d
kube-prometheus-stack-grafana-78457d9fc8-p48d9              3/3     Running   0          32d
kube-prometheus-stack-kube-state-metrics-5f6d6c64d5-xvcpw   1/1     Running   0          32d
kube-prometheus-stack-operator-6f4f8975fb-slt5c             1/1     Running   0          32d
kube-prometheus-stack-prometheus-node-exporter-jsfz6        1/1     Running   0          32d
kube-prometheus-stack-prometheus-node-exporter-qgxqp        1/1     Running   0          32d
kube-prometheus-stack-prometheus-node-exporter-xh2z7        1/1     Running   0          32d
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          32d
```

You will also notice a new application created in your ArgoCD UI called “kube-prometheus-stack”.

Let's login to Grafana now and see all metrics scraped by Prometheus displayed in beautiful Grafana dashboards. 

1.	Get Grafana admin password: 

```bash
kubectl get secret --namespace kube-prometheus-stack kube-prometheus-stack-grafana  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

2.	To access Grafana dashboard you should forward your local port 8080 to the Grafana port 3030 with next command:

```bash
kubectl port-forward kube-prometheus-stack-grafana-78457d9fc8-p48d9 -n kube-prometheus-stack --address 0.0.0.0 8080:3000
```
3. Open your browser and go to http://localhost:8080/. Then, login with username `admin` and above received password (default password: `prom-operator`).

4. Inside Grafana, under Dashboards you can browse different preconfigured dashboards available for you out of the box. 

As you can see, getting observability (logs and metrics) setup is pretty easy and straight forward with AWS EKS Blueprints Addons available for you. Now, let move into distributed tracing configuration.
