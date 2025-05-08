---
title: "ApplicationSet"
weight: 20
---

### 1. ApplicationSet

In the previous chapter, you deployed an application using an Application object. This application was deployed to the hub-cluster.
To deploy the same application to the spoke-cluster, you would need to create another Application manually.

![With ApplicationSet](/static/images/without-applicationset.png)

Instead of doing that every time, Argo CD offers a more scalable and automated solution — the ApplicationSet.

![With ApplicationSet](/static/images/with-applicationset.png)


Think of an ApplicationSet as a factory for Applications. It defines a template and uses generators to create multiple Application objects.

![ApplicationSet Template](/static/images/applicationset-template.png)



### 2. Static List Generator
Let’s create an ApplicationSet that deploys the Guestbook application to list of clusters. In this example to hub-cluster.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json highlightLines='12,13,14,15,16,17'}
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
        repoURL: https://github.com/argoproj/argocd-example-apps.git 
        path: guestbook
        targetRevision: HEAD
      destination:
        name: '{{.name}}'
        namespace: guestbook
EOF
:::
<!-- prettier-ignore-end -->

### 2. Apply Static List Generator

Apply the manifest

```bash
kubectl create ns guestbook
kubectl apply -f ~/environment/basics/guestbookApplicationSet.yaml
```
### 3. Verify Application

Navigate to the ArgoCD web UI. You should see the guestbook application listed.

![ApplicationSet Guestbook](/static/images/applicationset-guestbook.png)

After you create spoke-cluster, uncommenting the spoke-cluster section will automatically generate a second Application targeting that cluster. 

### 3. Clean Up

```bash
argocd appset delete guestbook  -y
kubectl delete ns guestbook
```

### Dynamic Generator

The static list generator requires you to manually add each cluster. A better approach is to dynamically select clusters using the Cluster generator, which selects clusters based on labels. 

ArgoCD supports different types of [Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/) like cluster, git, matrix and more, to dynamically generate Applications.



Let's explore how the Cluster generator works. The Cluster generator selects clusters based on labels defined on the cluster object. You can view these labels using the following command:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o yaml
```
A sample output might look like this. You'll notice that it already includes several labels,  which are populated automatically by GitOps Bridge. You will add labels to meet specific selection criteria in upcoming chapters.

:::code{showCopyAction=false showLineNumbers=false language=json highlightLines='14,15,16,17,18'}

```
apiVersion: v1
data:
  config: ewogICJ0bHNDbGllbnRDb25maWciOiB7CiAgICAiaW5zZWN1cmUiOiBmYWxzZQogIH0KfQo=
  name: aHViLWNsdXN0ZXI=
  server: aHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3Zj
kind: Secret
metadata:
  annotations:
    cluster_name: hub-cluster
    environment: control-plane
  creationTimestamp: "2024-10-03T18:51:28Z"
  labels:
    argocd.argoproj.io/secret-type: cluster
    cluster_name: hub-cluster
    enable_argocd: "true"
    environment: dev
  name: hub-cluster
  namespace: argocd
  resourceVersion: "6498"
  uid: ad023c6c-1a97-45c7-92b6-33a3f17021b7
type: Opaque
```

:::

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
