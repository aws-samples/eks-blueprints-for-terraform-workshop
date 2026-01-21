---
title: "Project"
weight: 50
---

<!-- cspell:disable-next-line -->

::video{id=C_2Vy85lWV4}

ArgoCD Projects provide Governance mechanism.

ArgoCD supports multi-tenancy. Tenancy refers to isolating access and resources between different groups or teams within the same ArgoCD instance. In this workshop, retail-store is a tenant. You can have other tenants like payments, ECommerce etc. Tenants are supported by different teams and don't share access.

Within the same tenant also needs varying degrees of access. For example retail-store application team with different roles and access requirements:

Team Structure:

- Team Leads: Need access to both dev and prod environments for oversight and troubleshooting
- Developers: Only need access to dev environment for daily development work
- Production Support: Can only monitor health in prod environment. Does not have privilege to create or delete applications
- DevOps: Can only Sync Applications in Production

You can achieve this access management with ArgoCD AppProjects.

With an Argo CD Project:

- Restrict the sources of content that can be used (Git, Helm, etc.)
- Restrict where Argo CD Applications can be deployed to (clusters and namespaces)
- Restrict which Kubernetes objects can be deployed (Deployments, services,CRDs, NetworkPolicies, etc.)
- Restrict who has access to which resources based on Group/User membership.

![Project Architecture](/static/images/argobasics/project-architecture.png)

Argo CD includes a Project called default. This Project allows the deployment of any resource to any cluster by anyone.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml }
kubectl  get appproject -n argocd default -oyaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    server: '*'
  sourceNamespaces:
  - argocd
  sourceRepos:
  - '*'
status: {}
:::
<!-- prettier-ignore-end -->

### 1. Restrict Default Project

ArgoCD application always belongs to a project. If you don't specify a project then it belongs to default project. You can't delete default project.

Let's restrict default project so that it has no permissions. This will make all applications deployed assigned to a project that follow governance.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='9,10,11,12,13'}
cd ~/environment/basics
cat <<'EOF' >> ~/environment/basics/restrictedDefaultProject.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  sourceRepos: []
  sourceNamespaces: []
  destinations: []
  clusterResourceWhitelist: []
  namespaceResourceBlacklist:
  - group: '*'
    kind: '*'
EOF
kubectl apply -f ~/environment/basics/restrictedDefaultProject.yaml
:::
<!-- prettier-ignore-end -->

Key Components:
- Line 9: No source repos allowed
- Line 10: Not allowed to deploy to any namespace
- Line 11: Not allowed to deploy to any clusters
- Line 12: All cluster actions are restricted
- Line 13: All namespace actions are restricted

We will create retail-store projects in "Register Dev Environment" and "Register Prod Environment" chapters

### 2. Admin Project

Let's restrict admin project so that it has permissions to create objects required for automation. 

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='9,10,11,12,13'}
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: admin-hub
  namespace: argocd
spec:
  description: "Project for administrator hub management of Apps, AppSets, and Projects"
  sourceRepos:
  - 392638250061.dkr.ecr.us-west-2.amazonaws.com
  - https://git-codecommit.us-west-2.amazonaws.com/v1/repos/platform
  - https://git-codecommit.us-west-2.amazonaws.com/v1/repos/platform/*
  destinations:
  - namespace: argocd
    name: hub 
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  
  roles:
  - name: admin-role
    description: Full management of GitOps resources within this project
    policies:
    # Format: p, <role>, <resource>, <action>, <object>, <allow/deny>
    
    # 1. Manage Applications within this project
    - p, proj:admin-hub:admin-role, applications, *, admin-hub/*, allow
    
    # 2. Manage ApplicationSets assigned to this project
    - p, proj:admin-hub:admin-role, applicationsets, *, admin-hub/*, allow
    
    # 3. Manage the AppProject itself (Self-service updates)
    - p, proj:admin-hub:admin-role, projects, *, admin-hub, allow
    
    groups:
    - f8b1f360-b091-70df-4581-146091cb8ec4
:::
<!-- prettier-ignore-end -->

Key Components:
- Line 9: No source repos allowed
- Line 10: Not allowed to deploy to any namespace
- Line 11: Not allowed to deploy to any clusters
- Line 12: All cluster actions are restricted
- Line 13: All namespace actions are restricted


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
cd ~/environment/basics
cp  $WORKSHOP_DIR/gitops/templates/project/admin-project.yaml ~/environment/basics
kubectl apply -f admin-project.yaml
:::
<!-- prettier-ignore-end -->

We will create retail-store projects in "Register Dev Environment" and "Register Prod Environment" chapters

### 3. Account Token Vs Project Token

Account Tokens:

- Scope: Global server access to all projects/apps the user has permissions for.
- Duration: Fixed 12 hours
- Created from: User Settings → Tokens
  You can find more info about Account Token in "Token-Based Access" chapter.

Project Tokens:

- Scope: Limited to single project only
- Duration: Configurable up to 1 year
- Created from: Project Settings → Role Tokens
