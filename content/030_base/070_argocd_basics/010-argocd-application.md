---
title: "Application"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=DMJhqkbhjgo}

If you want to deploy Kubernetes manifests, you need two key pieces of information: the local manifest file (what to deploy) and the target EKS cluster (where to deploy). For example:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=json }
kubectl apply -f ./local-path-to-manifest.yaml --context hub-cluster
:::
<!-- prettier-ignore-end -->

This command deploys the manifest to the hub-cluster

Argo CD follows a similar approach using an Application object. It defines what to deploy (from Git) and where to deploy it (target cluster and namespace).

# Create guestbook Application

In this section you will create guestbook Argo CD application. It will deploy the code from the application repository to the hub-cluster.

![Argo CD Application](/static/images/argocd-application.png)

### 1. Create guestbook Argo CD Application

An Argo CD **Application** is a special Kubernetes object (CRD) that tells Argo CD what to deploy from Git and where to deploy it. It keeps checking the actual state in your cluster and automatically syncs it to match what’s in Git.

In this step, you'll deploy an Argo CD Application. Each Application must specify:

- Source: the Git repository containing the manifests.
- Destination: the target Kubernetes cluster and namespace.

In the example below, we have placeholders for source (line 13) and destination (line 16). We will update these in latter steps.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='13,16'}
mkdir -p ~/environment/basics
cd ~/environment/basics
cat <<'EOF' >> ~/environment/basics/guestbook.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  # Source of the application manifests
  source:
    repoURL: <<APP REPO URL>> 
    path: guestbook
  destination:
    name: <<CLUSTER NAME>>
    namespace: guestbook   
  syncPolicy:
    automated: 
      prune: true
EOF
:::
<!-- prettier-ignore-end -->

Open guestbook workload in VSCode

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
code ~/environment/basics/guestbook.yaml
:::
<!-- prettier-ignore-end -->

### 2. Update Source (repoURL)

You will populate "eks-blueprints-workshop-gitops-apps" with guestbook manifest files.

We have already cloned this repo to the local "gitops-repos/workload" folder.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p "${GITOPS_DIR}/workload/guestbook"
cp -r /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/workload/guestbook/* "${GITOPS_DIR}/workload/guestbook/"
:::
<!-- prettier-ignore-end -->

Let's push changes to the application Git repository.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/gitops-repos/workload
git add .
git commit -m "initial guestbook"
git push --set-upstream origin main
:::
<!-- prettier-ignore-end -->

Navigate to the gitea Dashboard and copy HTTPS url of the application repository (eks-blueprints-workshop-gitops-apps).

Execute the following in the terminal to get gitea dashboard URL

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
gitea_credentials
:::
<!-- prettier-ignore-end -->

![Application GitRepo](/static/images/developer-repo-url.png)

You can also see the repository contains guestbook.

**Replace** `<<APP REPO URL>>` with the application repository url from step 3.

![Replace Developer GitRepo](/static/images/replace-developer-repo-url.png)

### 3. Configure Argo CD To Access Git Repository

Let's provide Argo CD access to the git repository with the Argo CD cli.

Replace `<APP_REPO_URL>` with the HTTPS URL copied in step 2. Do not use the URL from the command gitea_credentials. It is the URL for gitea dashboard.

Replace `<GIT_PASSWORD>` with the password for workshop-user in step 2. This is the password displayed with gitea_credentials. Gitea repos use the same password as the dashboard for convenience.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
argocd repo add <APP_REPO_URL> --name guestbookrepo --username workshop-user --password <GIT_PASSWORD> 
:::
<!-- prettier-ignore-end -->

like the following

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=json }
argocd repo add https://d2exxxxxxxx.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-apps.git --username workshop-user --password pmQ5mWKM3aiISbVvxxxxxxx
:::
<!-- prettier-ignore-end -->

You can validate new created git repo on the Argo CD dashboard. Navigate to Settings>Repositories

![GuestbookRepo](/static/images/guestbookrepo.png)

### 4. Update Destination

GitOps Bridge has already provided Argo CD with the access to hub-cluster.

Navigate Argo CD dashboard > Settings > Clusters > hub-cluster. Note name of the cluster (i.e hub-cluster).

![Hub Cluster](/static/images/hub-cluster-name.png)

**Replace** `<<CLUSTER NAME>>` with the cluster name in the guestbook manifest.

![Replace Developer GitRepo](/static/images/replace-hub-cluster.png)

### 5. Save the file

You have updated the file. Save the file.

Click on hamburger > File > Save

### 6. Apply guestbook manifest

When you apply this manifest:

- Argo CD creates an Application object.
- Argo CD syncs and deploys the resources (Deployment, Service, Pods) to the hub-cluster.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl create ns guestbook
kubectl apply -f ~/environment/basics/guestbook.yaml
:::
<!-- prettier-ignore-end -->

### 7. Verify the Application

Navigate to the Argo CD web UI. You should see the guestbook application listed.

![Argo CD Application Dashboard](/static/images/guestbook-ui.png)

You can click on the guestbook to see all the resources created by the guestbook Application.

You can check resources created by the Application (svc,deployment, replicaset, pods)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl get all -n guestbook
:::
<!-- prettier-ignore-end -->

# Auto Reconciliation

In this section you will modify manifest in the application git repo and watch it automatically reconciled with the cluster.

### 1. Update replica count

Currently replicas = 1 in guestbook-ui-deployment.yaml. Let's update replica to 3.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
sed -i 's/replicas: 1/replicas: 3/g' ~/environment/gitops-repos/workload/guestbook/guestbook-ui-deployment.yaml
:::
<!-- prettier-ignore-end -->

Let's push changes to Application Git repository.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/gitops-repos/workload
git add .
git commit -m "updated replica count to 3"
git push 
:::
<!-- prettier-ignore-end -->

### 2. Validate auto reconciliation

You can verify that Argo CD reconciled with the application git repository and deployment to 3 replicas. You should see 3 pods.

Argo CD polls the Git repository for changes **every 30 seconds** (as configured in this workshop) and automatically syncs any updates to the cluster. Reconciliation might take **a minute or two** if the server is under load.

** It may take a minute or two reconcile as server might be busy**

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl get pods -n guestbook
:::
<!-- prettier-ignore-end -->

### 8. Clean Up

Use Argo CD CLI to delete the application and its managed resources.

```bash
argocd app delete guestbook --cascade -y
kubectl delete ns guestbook --force

```

<!-- prettier-ignore-start -->
:::alert{header=Note type=warning}
It may take a few minutes to delete resources. 
:::
<!-- prettier-ignore-end -->
