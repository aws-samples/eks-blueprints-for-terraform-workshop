---
title: 'Namespace and Webstore workload'
weight: 50
---

In this chapter you will associate both namespace and workload application to webstore project created in the previous chapter

### 1. Set Project

```bash
sed -i "s/project: default/project: webstore/g" ~/environment/wgit/assets/platform/config/workload/webstore/workload/webstore-applicationset.yaml 
```
Changes by the code snippet is highlighted below.
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='9'}
$ git diff
--- a/assets/platform/config/workload/webstore/workload/webstore-applicationset.yaml
+++ b/assets/platform/config/workload/webstore/workload/webstore-applicationset.yaml
@@ -31,7 +31,7 @@ spec:
         component: '{{path.basename}}'
         workloads: 'true'
     spec:
-      project: default
+      project: webstore
       source:
         repoURL: '{{metadata.annotations.workload_repo_url}}'
         path: '{{path}}/{{metadata.labels.environment}}'
:::

### 2. Git commit
```bash
cd ~/environment/wgit
git add . 
git commit -m "set namespace and webstore applicationset project to webstore"
git push
```


### 3. Enable workloads and workload_webstore labels

```bash
sed -i "s/workload_webstore = false/workload_webstore = true/g" ~/environment/spoke/main.tf
```

### 4. Apply Terraform

```bash
cd ~/environment/spoke
terraform apply --auto-approve
```

### 5. Validate workload

::alert[It takes few minutes to deploy the workload and create a loadbalancer]{header="Important" type="warning"}

```bash
echo -n "Click here to open -> http://" ; kubectl get svc ui-nlb -n ui  --context spoke-staging --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo ""
```

Access  webstore in the browser.

![webstore](/static/images/webstore-ui.png)

Congratulations!, with this setup, you are able to deploy workloads applications using ArgoCD Projects and ApplicationSets, from a configuration cluster (the Hub) to one spoke cluster, but you can easilly duplicate this to manage severals spoke clusters with the same mechanisms.