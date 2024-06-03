---
title: 'Conclusion'
weight: 7
---

As a Team Riker member, you have successfully leveraged Karpenter's ability to schedule your workloads from your ArgoCD git repository and dynamically adapt the cluster size depending on application needs.

You already managed to rely on Kubecost to better adapt your resource workload requirements to reduce your cluster's costs.

We finally see how Spot instances could improve your cost savings, and how Karpenter and AWS managed Spot interruptions so that your workloads wouldn't be impaired.

### Reset environment

::alert[You can now scale back the skiapp to 3 replicas in your Github repository.]{header="Reset environment"}

In your codespace environment, reset skiapp to 3 replicas:

```bash
sed -i "s/^\(\s*\)replicas:.*/\1replicas: 3/" teams/team-riker/dev/templates/alb-skiapp/deployment.yaml
```

Commit the change:
```bash
git add .
git commit -m "reset skiapp to 3 replicas"
git push
```