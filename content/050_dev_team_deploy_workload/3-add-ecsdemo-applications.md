---
title: 'Deploy ECSDEMO microservice Applications'
weight: 3
hidden: true
---

## Deploy the ecsdemo application

What will we be doing in this section ?

We will be deploying an application composed of multiple microservices, much like in the real-world scenarios we face. We will deploy this application by adding 3 new teams in our EKS Blueprint _(one team for each microservice)_, and then leveraging ArgoCD to deploy our services in their appropriate team environment (namespace) in the EKS cluster.

::alert[We focus here on the Continuous Deployment (CD) part, and not of the building of the application microservices themselves, we will reuse the well knowned ecsdemo application already used on https://ecsworkshop.com and https://eksworkshop.com]{header="Information"}

![ecsdemo application](/static/images/crystal.svg)

## Adding new Teams to our EKS Blueprint

For now, go back to your cloud9 environment as we are going to update our terraform code.

We want to create dedicated kubernetes manifests in our new teams namespaces. For each team, we create directory inside the EKS Blueprints folder and create Kubernetes manifest, that will be installed at the namespace creation:

- An **ArgoCD AppProject** definition. It define a new project in argo, with our EKS cluster as destination and authorizations to sync between our team namespace and the **Github repositories** as the source for the deployments files.
- A **LimitRange object** to dynamically add and control Pod resources
  - We uses **LimitRange** in combination with **ResourceQuotas** so that we can control the team usage in the namespace, and it will automatically set default values if the application did not provide them

### ecsdemo-crystal

```bash
mkdir kubernetes/ecsdemo-crystal

cat << EOF > kubernetes/ecsdemo-crystal/limit-range.yaml
apiVersion: 'v1'
kind: 'LimitRange'
metadata:
  name: 'resource-limits'
  namespace: ecsdemo-crystal
spec:
  limits:
    - type: 'Container'
      max:
        cpu: '2'
        memory: '1Gi'
      min:
        cpu: '50m'
        memory: '4Mi'
      default:
        cpu: '300m'
        memory: '200Mi'
      defaultRequest:
        cpu: '200m'
        memory: '100Mi'
      maxLimitRequestRatio:
        cpu: '10'
EOF
```

### ecsdemo-nodejs

```bash
mkdir kubernetes/ecsdemo-nodejs

cat << EOF > kubernetes/ecsdemo-nodejs/limit-range.yaml
apiVersion: 'v1'
kind: 'LimitRange'
metadata:
  name: 'resource-limits'
  namespace: ecsdemo-nodejs
spec:
  limits:
    - type: 'Container'
      max:
        cpu: '2'
        memory: '1Gi'
      min:
        cpu: '50m'
        memory: '4Mi'
      default:
        cpu: '300m'
        memory: '200Mi'
      defaultRequest:
        cpu: '200m'
        memory: '100Mi'
      maxLimitRequestRatio:
        cpu: '10'
EOF
```

### ecsdemo-frontend

```bash
mkdir kubernetes/ecsdemo-frontend

cat << EOF > kubernetes/ecsdemo-frontend/limit-range.yaml
apiVersion: 'v1'
kind: 'LimitRange'
metadata:
  name: 'resource-limits'
  namespace: ecsdemo-frontend
spec:
  limits:
    - type: 'Container'
      max:
        cpu: '2'
        memory: '1Gi'
      min:
        cpu: '50m'
        memory: '4Mi'
      default:
        cpu: '300m'
        memory: '200Mi'
      defaultRequest:
        cpu: '200m'
        memory: '100Mi'
      maxLimitRequestRatio:
        cpu: '10'
EOF
```

## Deploy the new teams

Now, we need to create the associated teams within EKS Blueprint Terraform code. In the `main.tf` file in the `eks_blueprints` module under `application_teams` and below `team-riker` section add the following team definition:

```hcl
    ecsdemo-frontend = {
      "labels" = {
        "elbv2.k8s.aws/pod-readiness-gate-inject" = "enabled",
        "appName"                                 = "ecsdemo-frontend",
        "projectName"                             = "ecsdemo",
        "environment"                             = "dev",
      }

      "quota" = {
        "requests.cpu"    = "10000m",
        "requests.memory" = "20Gi",
        "limits.cpu"      = "20000m",
        "limits.memory"   = "50Gi",
        "pods"            = "10",
        "secrets"         = "10",
        "services"        = "10"
      }
      ## Deploy manifest from specified directory
      manifests_dir = "./kubernetes/ecsdemo-frontend"
      users         = [data.aws_caller_identity.current.arn]
    }

    ecsdemo-crystal = {
      "labels" = {
        "appName"     = "ecsdemo-crystal",
        "projectName" = "ecsdemo",
        "environment" = "dev",
      }

      "quota" = {
        "requests.cpu"    = "10000m",
        "requests.memory" = "20Gi",
        "limits.cpu"      = "20000m",
        "limits.memory"   = "50Gi",
        "pods"            = "10",
        "secrets"         = "10",
        "services"        = "10"
      }
      ## Deploy manifest from specified directory
      manifests_dir = "./kubernetes/ecsdemo-crystal"
      users         = [data.aws_caller_identity.current.arn]
    }

    ecsdemo-nodejs = {
      "labels" = {
        "appName"     = "ecsdemo-nodejs",
        "projectName" = "ecsdemo",
        "environment" = "dev"
      }
      "quota" = {
        "requests.cpu"    = "10000m",
        "requests.memory" = "20Gi",
        "limits.cpu"      = "20000m",
        "limits.memory"   = "50Gi",
        "pods"            = "10",
        "secrets"         = "10",
        "services"        = "10"
      }
      ## Deploy manifest from specified directory
      manifests_dir = "./kubernetes/ecsdemo-nodejs"
      users         = [data.aws_caller_identity.current.arn]
    }
```

Once we add our 3 new teams, we just need to apply this to our cluster

```bash
terraform apply --auto-approve
```

You should see 3 new namespaces

::alert[Remember we've setup aliases for the different Kubernetes tools? the `k` alias points to `kubectl`. More details [here](/020_setup/self_paced/3-install-kubernetes-tools.md)]{header="Important"}

```bash
kubectl get ns -l projectName=ecsdemo
```

```
NAME               STATUS   AGE
ecsdemo-crystal    Active   1m
ecsdemo-frontend   Active   1m
ecsdemo-nodejs     Active   1m
```

We can also check that we create our 3 new ArgoCD App Projects:

```bash
kubectl get appproject -A
```

```
NAMESPACE   NAME               AGE
argocd      default            14d
argocd      ecsdemo-crystal    1m
argocd      ecsdemo-frontend   1m
argocd      ecsdemo-nodejs     1m
```

And that our LimitRange objects has been correctly created in each of our newly namespaces:

```bash
kubectl get limitrange  -A
```

```
NAMESPACE          NAME              CREATED AT
ecsdemo-crystal    resource-limits   2022-07-18T13:48:49Z
ecsdemo-frontend   resource-limits   2022-07-18T13:48:48Z
ecsdemo-nodejs     resource-limits   2022-07-18T13:48:49Z
```

We can also checks for the quotas:

```bash
kubectl get resourcequotas  -A
```

```
NAMESPACE          NAME     AGE     REQUEST                                                                                          LIMIT
ecsdemo-crystal    quotas   6m48s   pods: 0/10, requests.cpu: 0/10, requests.memory: 0/20Gi, secrets: 2/10, services: 0/10           limits.cpu: 0/20, limits.memory: 0/50Gi
ecsdemo-frontend   quotas   6m48s   pods: 0/10, requests.cpu: 0/10, requests.memory: 0/20Gi, secrets: 2/10, services: 0/10           limits.cpu: 0/20, limits.memory: 0/50Gi
ecsdemo-nodejs     quotas   6m48s   pods: 0/10, requests.cpu: 0/10, requests.memory: 0/20Gi, secrets: 2/10, services: 0/10           limits.cpu: 0/20, limits.memory: 0/50Gi
team-riker         quotas   29h     pods: 9/15, requests.cpu: 2050m/10, requests.memory: 562Mi/20Gi, secrets: 2/10, services: 3/10   limits.cpu: 7050m/20, limits.memory: 1074Mi/50Gi
```

## Configure ECSDEMO ArgoCD deployment repo

Now we are going to let ArgoCD know about our **ArgoCD app of app** definition  for our ecsdemo 3-tier microservices to deploy in each of our team namespaces.

Open `locals.tf` and add our workload definition

```hcl
  #---------------------------------------------------------------
  # ARGOCD ECSDEMO APPLICATION
  #---------------------------------------------------------------

  ecsdemo_application = {
    path               = "multi-repo/argo-app-of-apps/dev"
    repo_url           = "https://github.com/seb-demo/eks-blueprints-workloads.git" # << don't change this line >>
    add_on_application = false
  }
```

::alert[Note: this time we will keep `seb-demo` here and not use your fork.]{header="Information"}

Then go to `main.tf` and add our application in the `argocd_applications` section.

> So Argo will look at the fork in `seb-demo` in the directory `multi-repo/argo-app-of-apps/dev` to find Kubernetes resources definitions to setup our applications. 

## Let Argo know of the new workload to deploy

Add the ecsdemo application in the list in `main.tf`

```hcl
  argocd_applications = {
    addons    = local.addon_application
    workloads = local.workload_application
    ecsdemo   = local.ecsdemo_application # Add this line
  }    
```

Again, we need to apply this change with terraform:

```bash
terraform apply --auto-approve
```

Let's walk through the definition of this application definition in the `seb-demo/eks-blueprint-workload` github repository:

You can see the directory we will sync here : https://github.com/seb-demo/eks-blueprints-workloads/tree/main/multi-repo/argo-app-of-apps/dev

It has this structure:

```
multi-repo/argo-app-of-apps/dev/
├── Chart.yaml
├── templates
│   ├── ecsdemo-crystal.yaml
│   ├── ecsdemo-frontend.yaml
│   └── ecsdemo-nodejs.yaml
└── values.yaml
```

You can see that that again it is a Helm chart format directory and we can review in the `values.yaml` file that for each application we reference another Git repository that contain the code to deploy each microservice.
Here we are interested in the application helm chart used to deploy in the subdirectories `kubernetes/helm/ecsdemo-*` of each microservice target git repository:

You can see in this file that we point to other git repo, one for each service: https://github.com/seb-demo/eks-blueprints-workloads/blob/main/multi-repo/argo-app-of-apps/dev/values.yaml

```yaml
spec:
  destination:
    server: https://kubernetes.default.svc
  apps:
    ecsdemoFrontend:
      repoURL: https://github.com/aws-containers/ecsdemo-frontend.git
      targetRevision: main
      path: kubernetes/helm/ecsdemo-frontend
    ecsdemoNodejs:
      repoURL: https://github.com/aws-containers/ecsdemo-nodejs.git
      targetRevision: main
      path: kubernetes/helm/ecsdemo-nodejs
    ecsdemoCrystal:
      repoURL: https://github.com/aws-containers/ecsdemo-crystal.git
      targetRevision: main
      path: kubernetes/helm/ecsdemo-crystal
```

If we open the [templates/ecsdemo-frontend.yaml](https://github.com/seb-demo/eks-blueprints-workloads/blob/main/multi-repo/argo-app-of-apps/dev/templates/ecsdemo-frontend.yaml) we can see specific values that we want to be injected in our application helm deployment. You can update this file to adapt the deployment of the application to your needs.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecsdemo-frontend
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: ecsdemo-frontend
  destination:
    namespace: ecsdemo-frontend
    server: {{.Values.spec.destination.server}}
  source:
    repoURL: {{.Values.spec.apps.ecsdemoFrontend.repoURL}}
    targetRevision: {{.Values.spec.apps.ecsdemoFrontend.targetRevision}}
    path: {{.Values.spec.apps.ecsdemoFrontend.path}}
    helm:
      parameters:
        - name: ingress.enabled
          value: 'true'
        - name: ingress.className
          value: 'alb'
        - name: ingress.annotations.alb\.ingress\.kubernetes\.io/group\.name
          value: 'ecsdemo'
        - name: ingress.annotations.alb\.ingress\.kubernetes\.io/scheme
          value: 'internet-facing'
        - name: ingress.annotations.alb\.ingress\.kubernetes\.io/target-type
          value: 'ip'
        - name: ingress.annotations.alb\.ingress\.kubernetes\.io/listen-ports
          value: '[{"HTTP": 80}]'
        - name: ingress.annotations.alb\.ingress\.kubernetes\.io/tags
          value: 'Environment=dev,Team=ecsdemo'
        - name: ingress.hosts[0].host
          value: ''
        - name: ingress.hosts[0].paths[0].path
          value: '/'
        - name: ingress.hosts[0].paths[0].pathType
          value: 'Prefix'
        - name: replicaCount
          value: '3'
        - name: image.repository
          value: 'public.ecr.aws/seb-demo/ecsdemo-frontend'
        - name: resources.requests.cpu
          value: '200m'
        - name: resources.limits.cpu
          value: '400m'
        - name: resources.requests.memory
          value: '256Mi'
        - name: resources.limits.memory
          value: '512Mi'

  syncPolicy:
    automated:
      prune: true
    syncOptions:
      - CreateNamespace=false # https://github.com/argoproj/argo-cd/issues/7799
```

> Here we add resources/limits configuration, and configured the ingress to uses the Application Load Balancer via dedicated annotations.

::alert[If you want to uses your Fork instead, you will have to replace those files as they differ from your fork repo.]{header="Important"}

## Deployment of the ECSDEMO application.

This should be done automatically, or you can go to the ArgoCD UI and check if it needs synchronization.

The application microservices pods should be running:

```bash
kubectl get pods -A | grep ecsdemo
```

```
ecsdemo-crystal    ecsdemo-crystal-56dd4d5f4-clxvx                             1/1     Running             0          42s
ecsdemo-crystal    ecsdemo-crystal-56dd4d5f4-fn95g                             1/1     Running             0          42s
ecsdemo-crystal    ecsdemo-crystal-56dd4d5f4-g7c86                             1/1     Running             0          42s
ecsdemo-frontend   ecsdemo-frontend-7b84c6dd54-b66mv                           1/1     Running             0          42s
ecsdemo-frontend   ecsdemo-frontend-7b84c6dd54-czdn4                           1/1     Running             0          42s
ecsdemo-frontend   ecsdemo-frontend-7b84c6dd54-znh74                           1/1     Running             0          42s
ecsdemo-nodejs     ecsdemo-nodejs-669bc64c56-7l5kc                             1/1     Running             0          43s
ecsdemo-nodejs     ecsdemo-nodejs-669bc64c56-7xjk7                             1/1     Running             0          43s
ecsdemo-nodejs     ecsdemo-nodejs-669bc64c56-mfklw                             1/1     Running             0          43s
```

And the ecsdemo-frontend app should be exposed through an ALB configure with the Kubernetes ingress, you can also find it in the ArgoCD Ui.

```bash
kubectl get ing -A | grep ecsdemo
```

```
ecsdemo-frontend   ecsdemo-frontend   alb     *       k8s-ecsdemo-f3cf86ec6a-1010682437.eu-west-1.elb.amazonaws.com             80      81s
```

You should be able to see our application as showed in the top of this page connecting to the ALB associated URL.
