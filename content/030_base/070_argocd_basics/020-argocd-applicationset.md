---
title: "ApplicationSet"
weight: 20
---

<!-- cspell:disable-next-line -->

::video{id=KKHVP2Ogq64}

In the previous chapter, you deployed an application using an ArgoCD Application object to the hub-cluster.
To deploy the same application to the spoke-cluster, you would need to create another ArgoCD Application manually.

![With ApplicationSet](/static/images/without-applicationset.png)

Instead of doing that every time, Argo CD offers a more scalable and automated solution — the ApplicationSet.

![With ApplicationSet](/static/images/with-applicationset.png)

Think of an ApplicationSet as a factory for ArgoCD Applications. It defines a template and uses generators to create multiple Application objects.

![ApplicationSet Template](/static/images/applicationset-template.png)

# Static List Generator

Let’s create an ApplicationSet that deploys the guestbook ArgoCD Application to list of clusters. In this example to hub-cluster.

### 1. Create guestbook ApplicationSet

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='12,13,14,15,16,17,25'}
cd ~/environment/basics
cat <<'EOF' >> ~/environment/basics/guestbookApplicationSet.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - list:
      elements:
      - cluster: hub-cluster
        name: hub-cluster
      # - cluster: spoke-cluster
      #  name: spoke-cluster

  template:
    metadata:
      name: '{{.cluster}}-guestbook'
    spec:
      project: "default"
      source:
        repoURL: <<APP REPO URL>>
        path: guestbook
        targetRevision: HEAD
      destination:
        name: '{{.name}}'
        namespace: guestbook
      syncPolicy:
        automated: {}        

EOF
:::
<!-- prettier-ignore-end -->

### 2. Update repoURL

This ApplicationSet is using a placeholder `<<APP REPO URL>>` for the Git repository URL. In this step, we’ll update it with the actual URL of your Guestbook app repo.

Open guestbook applicationset in VSCode.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
code ~/environment/basics/guestbookApplicationSet.yaml
:::
<!-- prettier-ignore-end -->

Navigate to the gitea Dashboard and copy HTTPS url of the application repository(eks-blueprints-workshop-gitops-apps).

:::alert{header="Gitea Dashboard URL"}
You execute the following command in the terminal for gitea url.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json}
gitea_credentials
:::
<!-- prettier-ignore-end -->

![Application GitRepo](/static/images/developer-repo-url.png)

**Replace** `<<APP REPO URL>>` with the application repository url

### 3. Save the file
You have updated the file. Save the file.

Click on hamburger > File > Save


### 4. Apply Static List Generator

Apply the manifest

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json}
kubectl create ns guestbook
kubectl apply -f ~/environment/basics/guestbookApplicationSet.yaml
:::
<!-- prettier-ignore-end -->

### 5. Verify Application

Navigate to the ArgoCD web UI. You should see the guestbook ArgoCD Application listed.

![ApplicationSet Guestbook](/static/images/applicationset-guestbook.png)

After you create spoke-cluster, uncommenting the spoke-cluster section will automatically generate a second Application targeting that cluster.

### 3. Clean Up

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json}
argocd appset delete guestbook  -y
kubectl delete ns guestbook --force
kubectl get secrets -n argocd -o json | jq -r '
  .items[]
  | select(.data != null)
  | select(any(.data[]?; @base64d == "guestbookrepo"))
  | .metadata.name
' | xargs -r -I{} kubectl delete secret -n argocd {}
:::
<!-- prettier-ignore-end -->

<!-- prettier-ignore-start -->
:::alert{header=Note type=warning}
It may take a few minutes to delete resources. 
:::
<!-- prettier-ignore-end -->

# Dynamic Generator

The static list generator requires you to manually add each cluster. A better approach is to dynamically select clusters using the Cluster generator, which selects clusters based on labels.

ArgoCD supports different types of [Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/) like cluster, git, matrix and more, to dynamically generate Applications.

## Cluster Generator

Let's explore how the Cluster generator works. The Cluster generator selects clusters based on **labels** defined on the cluster object. You can view labels navigating to ArgoCD dashboard > Settings > Clusters > hub-cluster:

![Hub Cluster Labels](/static/images/hubcluster-initial-labels.png)

These labels are created by GitOps Bridge.

Labels are similar to AWS tags. For example, in AWS you can designate a role for an EC2 instance using tags like app=webserver or app=appserver. These tags help identify the role or purpose of the instance.

Labels in ArgoCD work in a similar way. You can assign labels to clusters to indicate their role, environment, or purpose. For instance, labeling a cluster with workload_webstore=true(indicating it can deploy the Webstore app) or environment=staging( indicating it should receive staging versions) allows tools like Argo CD ApplicationSet to target the right clusters dynamically based on these roles.

Let's look at a few examples of how to use labels with the Cluster generator.

Let's say there are 3 cluster objects - hub-cluster, spoke-staging and spoke-prod with different labels (key value pairs).

The following is a code snippet of an ApplicationSet. The cluster generator creates one application because one cluster label matches the criteria.

```
  .
  .
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: hub
  .
  .
```

![applicationset](/static/images/applicationset-controlplane.png)

The following generator creates 2 applications because 2 cluster labels match the criteria.

```
  generators:
  - clusters:
      selector:
        matchLabels:
          workloads: true
```

![applicationset](/static/images/applicationset-workloads.png)

If you update the labels on a cluster, the ApplicationSet controller will **dynamically** generate new ArgoCD Applications or delete existing ones based on the updated label values.

For example, in the scenario above, if you set workloads=true on the hub-cluster, the ApplicationSet will automatically generate an additional Application targeting that cluster.
