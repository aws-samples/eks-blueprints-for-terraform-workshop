---
title: 'Deploy a Green Version'
weight: 3
hidden: false
---

Now that we have our Blue version running of the `skiapp`, we want to deploy a Green version, which visually has the top navigation changed. We've removed several items from the navigation menu.

## Update Rollout in Source Control

Since our Rollout definition is within our **Workloads** repo, let's change the image used and set it to V2 (Green).


In the `rollout.yaml`, change the image to `sharepointoscar/skiapp:v2` as shown below.

Open the file with codespace or with your preferred tool:

```bash
code teams/team-riker/dev/templates/alb-skiapp/rollout.yaml
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
...
    spec:
      containers:
        - name: skiapp
          image: sharepointoscar/skiapp:v2
...
```

Push the change:

```bash
git add .
git commit -m "change Rollout to skiapp v2"
git push
```

Once you've checked in the file in source control and merged it with the main branch, ArgoCD will pick up the change and sync and update the Rollout so that the Preview Service shows the (Green) v2 version of our app.

You can force the Sync in the UI or in the cloud9:

```bash
argocd app sync team-riker
```

You should see with the `kubectl argo rollouts list rollouts -n team-riker -w` you ran previously that we have 2 revisions in our rollout:
- revision:1 is Stable and Active.
- revision:2 is in Preview.

### View it on the Argo Rollout Dashboard

To be able to open the Argo Rollout Dashboard inside Cloud9, we need to forward port 8080 to 3100:

```bash
sudo iptables -t nat -I OUTPUT -o lo -p tcp --dport 8080 -j REDIRECT --to-port 3100
sudo iptables -I INPUT -p tcp --dport 3100
sudo iptables -I INPUT -p tcp --dport 8080
```

Create the Argo Rollouts Dashboard using the following command:

```bash
kubectl argo rollouts dashboard
```

Open the Browser Preview by using the Cloud9 menu option `Tools > Preview > Preview Running Application`.

![Skiapp Rollout Status](/static/images/argo-rollout-green-prev.png)
**FIGURE 3 - Argo Rollouts Dashboard shows Blue and Green Revisions**

::alert[Note: There seems to be an issue if you are using Safari, but working on Chrome or Firefox]{header="Important"}

At this point, our Rollout is paused. It is during this time that folks on the design team can view the Green version of the app, test it, etc.

::alert[To obtain the Preview Ingress URL, simply login to the ArgoCD UI or use `kubectl get ing -n team-riker`]{header="Important"}

We can see in the ArgoCD UI that the skiapp-rollout has created two replicaset, one for each version of the app.

![](/static/images/argocd-rollout-preview.png)

If you open the `skiapp-service` and the `skiapp-service-preview`, looking at the **Live Manifest**, you can see that the selector has been updated and now also references a label containing the rollout hash. This is how Argo Rollouts makes the request come to one or the other version.

```yaml
  selector:
    app: skiapp
    rollouts-pod-template-hash: cd6c4b557
```

> You can see the label's selector change as we promote our rollout.

## Promote the new version

Assuming you have approval to go live with the Green version of the app, we simply **Promote** the version via the Argo Rollouts dashboard. Our v2 version of the app is now the Blue, Stable and Active version.

![Promoted App version](/static/images/argocd-promote-green.png)
**FIGURE 4 - Promoting Green Revision to Blue (stable, active)**

You can also do it with the Cli

```bash
kubectl argo rollouts promote skiapp-rollout -n team-riker
```

After Argo Rollout has synchronized everything, you should have only revision:2 deployed with only three pods running.

![](/static/images/argocd-rollout-preview-promoted.png)

# Rolling Back to V1

Rolling back to the previous version can be as easy as clicking the **Rollback** button on the Argo Rollouts Dashboard, or using the `kubectl` CLI, or using the ArgoCD Admin web console.

```
kubectl argo rollouts undo skiapp-rollout -n team-riker
```

::alert[In this case, you will have an OutofSync between your desired state defined in the workload repository and the manual rollback you did with the Rollout dashboard. Forcing a new sync will re-trigger the migration to v2, it is recommanded to make changes within the workload repository.]{header="Important"}

>It's not necessary to rollback for now.

# Cleanup

We finished this module with the Argo Rollout; you can now remove the rollout to continue the workshop:

1. Delete the `rollout.yaml` file and commit the change.

From your eks-blueprint-workload code location or Codespace:

```bash
rm teams/team-riker/dev/templates/alb-skiapp/rollout.yaml
```

```bash
git add .
git commit -m "remove Rollout"
git push
```

2. Sync ArgoCD, and once ArgoCD has deleted the deployment, check that you still have access to the skiapp application.