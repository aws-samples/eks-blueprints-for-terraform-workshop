---
title: "Webstore Deployment"
weight: 10
---


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='22,32'}
for svc in /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/workload/webstore/*; do
  svc_name=$(basename $svc)
  mkdir -p ${GITOPS_DIR}/workload/webstore/$svc_name
  cp -r $svc/base $svc/dev ${GITOPS_DIR}/workload/webstore/$svc_name/ 2>/dev/null
done
:::
<!-- prettier-ignore-end -->



### 2. Git commit

```bash
cd $GITOPS_DIR/workload
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

