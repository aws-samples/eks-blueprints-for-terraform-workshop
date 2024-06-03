---
title: 'Add App to Workloads Repo'
weight: 1
---

## Meet the ArgoCD Workload Application repository

We have created a [workload repository sample](https://github.com/aws-samples/eks-blueprints-workloads) respecting the [ArgoCD App of App pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern).

Fork this repository if it's not already done, and check that it is correctly updated in the `locals.tf` file.

### The Terraform configuration 

In our `workload_application` configuration in the `locals.tf` file we previously added a configuration to declare an ArgoCD application.

```bash
grep -A 25 workload_application ~/environment/eks-blueprint/modules/eks_cluster/locals.tf 
```

:::code{showCopyAction=false showLineNumbers=false language=hcl}
  workload_application = {
    path                = local.workload_repo_path # <-- we could also to blue/green on the workload repo path like: envs/dev-blue / envs/dev-green
    repo_url            = local.workload_repo_url
    target_revision     = local.workload_repo_revision

    add_on_application  = false
    
    values = {
      labels = {
        env   = local.env
      }
      spec = {
        source = {
          repoURL        = local.workload_repo_url
          targetRevision = local.workload_repo_revision
        }
        blueprint                = "terraform"
        clusterName              = local.name
        #karpenterInstanceProfile = module.karpenter.instance_profile_name # Activate to enable Karpenter manifests (only when Karpenter add-on will be enabled in the Karpenter workshop)
        env                      = local.env
      }
    }
  }  

}
:::

It uses variables we have defined in our `terraform.tfvars` file: 

```bash
cat ~/environment/eks-blueprint/terraform.tfvars
```

You should have something similar, updated with the current region, and your GITHUB_USER name where you fork the repository:

:::code{showCopyAction=false showLineNumbers=false language=hcl}
aws_region             = "eu-west-1"
environment_name       = "eks-blueprint"
eks_admin_role_name    = "WSParticipantRole"

addons_repo_url        = "https://github.com/aws-samples/eks-blueprints-add-ons.git"

workload_repo_url      = "https://github.com/aws-samples/eks-blueprints-workloads.git"
workload_repo_revision = "main"
workload_repo_path     = "envs/dev"
:::

We configure the `workload_repo_path` path to be `env/dev`. That means that ArgoCD will synchronize the content of this repo/path into our EKS cluster.

### The envs/dev repository

This is how the [target](https://github.com/aws-samples/eks-blueprints-workloads/tree/main/envs/dev) for our configuration looks like:

```
envs/dev/
├── Chart.yaml
├── templates
│   ├── team-burnham.yaml
│   ├── team-carmen.yaml
│   ├── team-geordi.yaml
│   └── team-riker.yaml
└── values.yaml
```

You can see that this structure is for a [Helm Chart](https://helm.sh) in which we defined several teams workloads. So if you are familiar with Helm charts, kudos!

The directory as a default [env/dev/values.yaml](https://github.com/aws-samples/eks-blueprints-workloads/blob/main/envs/dev/values.yaml) which is configured with default values:

```yaml
spec:
  destination:
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/aws-samples/eks-blueprints-workloads # This will be surcharged by our Terraform workload_application.values.spec.source.repoURL variable.
    targetRevision: main
  ...
```

...but we are relying on our Terraform local `workloads_application.values` to surcharge those parameters (at least we changed the source.repoURL to point to your fork through Terraform).

In the [templates](https://github.com/aws-samples/eks-blueprints-workloads/tree/main/envs/dev/templates) directory, we can see files representing Kubernetes's kind `Application` of ArgoCD.


### The Team Riker Application

Now, let's have a look at the [team-riker.yaml](https://github.com/aws-samples/eks-blueprints-workloads/blob/main/envs/dev/templates/team-riker.yaml#L18) helm template file. It's an [ArgoCD Application](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications) defining the team-riker application with a code source from the same GitHub repository under the path `teams/team-riker/dev`.

So now, let's look under the [teams/team-riker/dev](https://github.com/seb-tmp/eks-blueprints-workloads/tree/main/teams/team-riker/dev) directory structure.

```
├── Chart.yaml
├── templates
│   ├── 2048.yaml
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
└── values.yaml
```

Again, it uses the Helm chart format.

The files under the templates directory are rendered using Helm and deployed into the EKS cluster into the `team-riker` namespace.

This is known as the [App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern)

![Argo App of App](/static/images/terraform-argo-app-app.png)

## Activate our workload GitOps with the Terraform code

Remember, in the `main.tf` file, when we configured Argo, we chose to activate only the addon repository.
Go back to the cloud9 to update the `~/environment/eks-blueprint/modules/eks_cluster/main.tf` and uncomment the `workloads` application.

```bash
sed -i "s/^\(\s*\)#\(workloads = local.workload_application\)/\1\2/" ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

Check the result, which should be like: 

```bash
grep -A 4 argocd_application ~/environment/eks-blueprint/modules/eks_cluster/main.tf
```

:::code{showCopyAction=false showLineNumbers=false language=hcl}
  argocd_applications = {
    addons = local.addon_application
    workloads = local.workload_application # <- uncomment this line
  }
:::

And then,

```bash
cd ~/environment/eks-blueprint/eks-blue
# It is always a good practice to use a dry-run command
terraform plan
```

Review the change and apply: 

```bash
# Apply changes to provision the Platform Team
terraform apply -auto-approve
```

Since our changes are pushed to the main branch of our workload git repository, ArgoCD is now aware of them and will automatically sync the main branch with our EKS cluster. Your ArgoCD dashboard should look like the following:

If changes are not appearing, you may need to resync the workloads Application in ArgoCD UI: Click on `workloads` and click on the `sync` button.

![ArgoCD Dashboard](/static/images/argo_dashboard.png)

You can click in the ArgoUI on the team-riker box.

Then you will see all the Kubernetes objects that are deployed in the team-riker namespace:

![ArgoCD team-riker](/static/images/team_riker_app.png)

## Add our website manifest for the new SkiApp

We were asked, as members of Team Riker, to deploy a new website in our Kubernetes namespace, the SkiApp application. For that, we will need to add some kubernetes manifests to the `teams/team-riker/dev/templates` directory.

::alert[There are several ways to do it. You can either clone your repo, edit the files with your favorite IDE, and push them back to github, or you can use GitHub Codespace to have a remote VsCode and make changes there, or you can use the GitHub interface to push your changes.]{header="Important" type="info"}

Open your clone of the [Workloads Repository](https://github.com/aws-samples/eks-blueprints-workloads) in your preferred method (or [GitHub Codespace](https://github.com/features/codespaces))

### Create a GitHub CodeSpace from your Fork  (better with Chrome or Firefox)

![GitHub Create CodeSpace](/static/images/github-codespace.png)

We are going to create a new directory and files under `teams/team-riker/dev/templates`, which represent the website manifests we want to deploy. From the root directory of the git repository, run the following command:

```bash
mkdir -p teams/team-riker/dev/templates/alb-skiapp

curl ':assetUrl{path="/alb-skiapp/deployment.yaml" source=s3}' --output teams/team-riker/dev/templates/alb-skiapp/deployment.yaml
curl ':assetUrl{path="/alb-skiapp/ingress.yaml" source=s3}' --output teams/team-riker/dev/templates/alb-skiapp/ingress.yaml
curl ':assetUrl{path="/alb-skiapp/service.yaml" source=s3}' --output teams/team-riker/dev/templates/alb-skiapp/service.yaml
```

::::expand{header="...or do it with the GitHub interface:"}

Create a new file in the `teams/team-riker/dev/templates` directory:
![GitHub Create File](/static/images/github-create-file.png)

Create a new directory `alb-skiapp` and file `deployment.yaml` and copy the [deployment.yaml](:assetUrl{path="/alb-skiapp/deployment.yaml" source=s3}) content.

![GitHub Create File](/static/images/github-deployment.png)

Then do the same for the two remaining files [service.yaml](:assetUrl{path="/alb-skiapp/service.yaml" source=s3}) and [ingress.yaml](:assetUrl{path="/alb-skiapp/ingress.yaml" source=s3})

::::


Now the repository should be like

```bash
tree teams/team-riker/dev/templates/alb-skiapp
```

```
teams/team-riker/dev/templates/alb-skiapp
├── deployment.yaml
├── ingress.yaml
└── service.yaml
```

You can explore the three files to understand what we are adding.

::alert[In the EKS Blueprints, we have only configured Team Riker as of now. If we deploy as is, all four teams will be created. But we only focus on the team-riker in this workshop; to avoid any confusion or conflict, we will remove unnecessary teams.]{header="Important" type="info"}

Please remove other teams we don't care for now, and we also removed another app from team-riker.

Execute this command in the CodeSpace or remove the files from the GitHub UI or you'd prefer: 

```bash
rm envs/dev/templates/team-burnham.yaml
rm envs/dev/templates/team-carmen.yaml 
rm envs/dev/templates/team-geordie.yaml
rm teams/team-riker/dev/templates/2048.yaml
```


When ready, you must check-in your code on GitHub using the following command:

```bash
git add .
git commit -m "feature: adding skiapp and keeping only team-riker"
git push
```

### See it went live in ArgoCD

Go back to the ArgoCD UI and click on the Sync button in the team-riker application.

> Argo Auto Sync has been [enabled](https://github.com/seb-tmp/eks-blueprints-workloads/blob/main/envs/dev/templates/team-riker.yaml?#L22-L24) by default in the team-riker application, but you can accelerate by manually clicking on the **Sync** button.

You should see your last commit at the top of the screen and the new application appearing:
![ArgoCD team-riker](/static/images/skiapp-ingress.png)

To access our Ski App application, you can now click on the skiapp-ingress, as shown in red in the previous picture.

::alert[It can take a few minutes for the load balancer to be created and the Domain name to be propagated.]{header="Important" type="info"}

![ArgoCD Dashboard](/static/images/skiapp_workload.png)

::alert[For a production application, we would have to configure our ingress to use a custom domain name and use the external-dns add-on to dynamically configure our route53 hosted zone from the ingress configuration. You can find a more complete example in [this example](https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/examples/blue-green-upgrade) of the EKS Blueprints.]{header="Important"}

So our **Riker Application Team** has successfully published their website to the EKS cluster provided by the **Platform Team**. This pattern can be reused with your actual applications. If you want to see more EKS Blueprints teams and ArgoCD integration, you can go to the next module.