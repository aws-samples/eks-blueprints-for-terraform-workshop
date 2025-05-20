---
title: "Deploy GitOps Bridge to Automate Add-on Management"
weight: 20
---
In this chapter, you'll automate the installation and lifecycle management of cluster add-ons using Argo CD and GitOps Bridge.

GitOps Bridge provides a pre-built Helm chart that simplifies managing add-ons using a declarative approach. This chart lives in the addons repository.

![GitOps Bridge Helm](/static/images/gitops-bridge-helm.png)



### 1. Configure Addons ApplicationSet

In a earlier bootstrap chapter, you created an Argo CD Application that continuously watches the bootstrap/ folder in the platform Git repository. Now, you'll add an ApplicationSet to bootstrap folder that dynamically deploys the GitOps Bridge Helm chart to hub-cluster. 

![Addons ApplicationSet](/static/images/addons-applicationset-bootstrap.png)


Now, you’ll add the cluster-addons ApplicationSet to the bootstrap folder in the platform Git repository. The highlighted lines below show the repoURL and path pointing to the GitOps Bridge Helm chart in the addons Git repository.


:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='33-34'}
cat <<'EOF' >> ~/environment/gitops-repos/platform/bootstrap/addons-applicationset.yaml
   
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: create-cluster-addons
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: true
  goTemplate: true
  goTemplateOptions:
    - missingkey=error
  generators:
    - clusters:
        selector:
          matchLabels:
            fleet_member: hub
        values:
          addonChart: gitops-bridge
  template:
    metadata:
      name: cluster-addons
      finalizers:
        # This is here only for workshop purposes. In a real-world scenario, you should not use this
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      sources:
        - ref: values
          repoURL: "{{.metadata.annotations.addons_repo_url}}"
          targetRevision: "{{.metadata.annotations.addons_repo_revision}}"
        - repoURL: "{{.metadata.annotations.addons_repo_url}}"
          path: "{{.metadata.annotations.addons_repo_basepath}}charts/{{.values.addonChart}}"
          targetRevision: "{{.metadata.annotations.addons_repo_revision}}"
          helm:
            valuesObject:
              #selectorMatchLabels:
              #  fleet_member: control-plane
            ignoreMissingValueFiles: true
            valueFiles:
              - "$values/{{.metadata.annotations.addons_repo_basepath}}default/addons/{{.values.addonChart}}/values.yaml"
              - "$values/{{.metadata.annotations.addons_repo_basepath}}environments/{{.metadata.labels.environment}}/addons/{{.values.addonChart}}/values.yaml"
              - "$values/{{.metadata.annotations.addons_repo_basepath}}clusters/{{.name}}/addons/{{.values.addonChart}}/values.yaml"
              - "$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/default/addons/{{.values.addonChart}}/values.yaml"
              - "$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/environments/{{.metadata.labels.environment}}/addons/{{.values.addonChart}}/values.yaml"
              - "$values/{{.metadata.annotations.addons_repo_basepath}}tenants/{{.metadata.labels.tenant}}/clusters/{{.name}}/addons/{{.values.addonChart}}/values.yaml"
      destination:
        namespace: argocd
        name: "{{.name}}"
      syncPolicy:
        automated:
          selfHeal: false
          allowEmpty: true
          prune: false
        retry:
          limit: 100
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true 

EOF
:::


Commit and push the updated ApplicationSet configuration to the platform repository.

```bash
git -C ${GITOPS_DIR}/platform add .  || true
git -C ${GITOPS_DIR}/platform commit -m "add addon applicationset" || true
git -C ${GITOPS_DIR}/platform push || true
```

### 2. Validate addons ApplicationSet

Navigate to the Argo CD dashboard in the UI and verify that the "cluster-addons" Application was created successfully.

![addons-rootapp](/static/images/addons-rootapp.jpg)

:::alert{header="Important" type="warning"}
We are using port-forward to access Argo CD UI in this workshop.
While this setup is convenient, the websocket sync mechanism or the UI is not working properly, you may need to totally refresh the page (Ctrl+R) to see updates in the UI.

Also, if during the workshop, the UI became not responsive, that may be because the port-forward has stopped. you can re-enable it at any time by executing again

```bash
argocd_hub_credentials
```

:::

In the Argo CD dashboard, click on the "bootstrap" Application and examine the list of Applications that were generated from it.

![addons-rootapp](/static/images/cluster-addon-creation-flow.png)

The **cluster-addons** Application creates ApplicationSets for all add-ons defined in the GitOps add-ons repository.


![cluster-addons](/static/images/cluster-addons-applicationsets.jpg)

Currently, no add-ons are deployed because their installation has not been activated in the cluster secret labels.

:::alert{header="Important" type="info"}

1. The ApplicationSet **cluster-addons**, point to the **eks-blueprint-workshop-gitops-addons** git repository which is synchronized from `~/environment/gitops-repos/addons` directory.

2. The Addons to be deployed, must be enabled in the cluster secret, which is not the case at the moment.
   :::
