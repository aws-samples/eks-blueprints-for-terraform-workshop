---
title: 'Deploy Rollout App'
weight: 2
hidden: false
---

## Using a Blue/Green Strategy

Now that we have Argo Rollouts fully configured, it is time to take it for a spin.

Using our `skiapp` application, we are going to deploy using the blue-green deployment strategy.

Let's define our [ArgoCD Rollout](https://argo-rollouts.readthedocs.io/en/stable/features/specification/) Kubernetes object!

## Add rollout.yaml to the alb-skiapp folder

In our previous module :link[Add App to Workloads Repo]{href="../1-add-app-to-workloads-repo.md"} , we created the `alb-skiapp` folder and added the `ingress.yaml`, `deployment.yaml` and `service.yaml` files.

We now need to add an additional file called `rollout.yaml` that will replace the `deployment.yaml` to that folder, and we will end up with the following structure:

```
├── Chart.yaml
├── templates
│   ├── alb-skiapp
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── rollout.yaml
│   │   └── service.yaml
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
└── values.yaml
```

Once you've located the workloads repository and `alb-skiapp` folder, let's add an additional file to define the Rollout.

## Add the Rollout YAML definition

Inside the `alb-skiapp` folder, add the following definition in a new file named `rollout.yaml`. We are adding three different resources, which include a **Rollout**, a **Service** to use for the Preview of our app, and lastly, we are creating an **Ingress** to use with our Preview Service.

Paste this command in your codespace or copy the [rollout.yaml](:assetUrl{path="/alb-skiapp/rollout.yaml" source=s3}) file, and paste it in the correct directory.

```bash
cat << EOF > teams/team-riker/dev/templates/alb-skiapp/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: skiapp-rollout
  namespace: team-riker
  labels:
    app: skiapp
spec:
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: skiapp
  template:
    metadata:
      labels:
        app: skiapp
    spec:
      containers:
      - name: skiapp
        image: sharepointoscar/skiapp:v1
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        resources:
            requests:
                memory: "64Mi"
                cpu: "250m"
            limits:
                memory: "128Mi"
                cpu: "500m"
      {{ if .Values.spec.karpenterInstanceProfile }}
      nodeSelector: # <- add nodeselector, toleration and spread constraitns
        team: default
        type: karpenter
      tolerations:
        - key: 'karpenter'
          operator: 'Exists'
          effect: 'NoSchedule'
      {{ end }}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: skiapp          
      tolerations:
        - key: 'karpenter'
          operator: 'Exists'
          effect: 'NoSchedule'                
  strategy:
    blueGreen:
      autoPromotionEnabled: false
      activeService: skiapp-service
      previewService: skiapp-service-preview
---
apiVersion: v1
kind: Service
metadata:
  name: skiapp-service-preview
  namespace: team-riker
spec:
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  type: NodePort
  selector:
    app: skiapp
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: skiapp-ingress-preview
  namespace: team-riker
  annotations:
    alb.ingress.kubernetes.io/group.name: riker-preview
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/tags: 'Environment=dev,Team=Riker'
spec:
  ingressClassName: alb
  rules:
  - host: 
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: skiapp-service-preview
            port:
              number: 80
EOF
```

This creates a **Rollout** to manage our application with:
- **nodeSelector** to select Karpenter nodes (only if we provide the Karpenter Profile in values).
- **toleration** to allow scheduling on Karpenter taints (only if we provide the Karpenter Profile in values).
- **topologySpreadConstraints** to spread our workloads on each AZ.
- A **Service** for the preview version.
- An **ingress** to expose the preview Service.

Save the file in your source code.
We can also delete the old deployment.yaml file, as now we use Rollout to create our pods.

```bash
git add .
git commit -m "feature: adding rollout resource"
git push
```

Go to the ArgoCD Dashboard and see the Rollout deployed in the `team-riker` application. If it is not deployed yet, you can click on the **Sync** button to force it.

We already have installed the [Argo Rollouts Kubectl plugin](https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation) as part of our bootstrap script.

Check the status of the Rollout with the following command:

```bash
kubectl argo rollouts list rollouts -n team-riker
```

:::code{showCopyAction=false language=bash}
NAME            STRATEGY   STATUS        STEP  SET-WEIGHT  READY  DESIRED  UP-TO-DATE  AVAILABLE
skiapp-rollout  BlueGreen  Healthy       -     -           3/3    3        3           3
:::

We can also Watch the status of the Rollout. Open this command in a new terminal:

```bash
kubectl argo rollouts get rollout skiapp-rollout -n team-riker -w
```

:::code{showCopyAction=false language=bash}
Name:            skiapp-rollout
Namespace:       team-riker
Status:          ✔ Healthy
Strategy:        BlueGreen
Images:          sharepointoscar/skiapp:v2 (stable, active)
Replicas:
  Desired:       3
  Current:       3
  Updated:       3
  Ready:         3
  Available:     3

NAME                                        KIND        STATUS     AGE    INFO
⟳ skiapp-rollout                            Rollout     ✔ Healthy  5m43s  
└──# revision:1                                                           
   └──⧉ skiapp-rollout-7594c7c67f           ReplicaSet  ✔ Healthy  5m42s  stable,active
      ├──□ skiapp-rollout-7594c7c67f-494bk  Pod         ✔ Running  5m42s  ready:1/1
      ├──□ skiapp-rollout-7594c7c67f-l4vcx  Pod         ✔ Running  5m42s  ready:1/1
      └──□ skiapp-rollout-7594c7c67f-khkxh  Pod         ✔ Running  4m48s  ready:1/1
:::

## How is the Rollout exposed?

Remember, we started to create a `deployment.yaml`, and a `service.yaml` exposed with it's associated `ingress.yaml` that has created our Load Balancer.

Look at the live `service.yaml` yaml content, you should see an evolution in it-s Pod Selectors.

```bash
kubectl get svc -n team-riker skiapp-service -o json | jq ".spec.selector"
```

:::code{showCopyAction=false language=bash}
{
  "app": "skiapp",
  "rollouts-pod-template-hash": "7594c7c67f"
}
:::

The `rollouts-pod-template-hash` has been added by the Argo Rollout controller so that our service only target pods that are created by the Rollout `skiapp-rollout` Kubernetes object.

1. Sync ArgoCD, and once ArgoCD has deleted the deployment, check that you still have access to the skiapp application.

```bash
argocd app sync team-riker
```

```bash
curl $(kubectl get ingress -n team-riker skiapp-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

Should respond with the app html.