#!/bin/bash

set -uo pipefail


#Activate AutoSync
#kubectl  --context hub patch applicationset appofapps -n argocd --type=json -p='[{"op": "add", "path": "/spec/template/spec/syncPolicy", "value": {"automated": {"prune": true, "selfHeal": true}}}]'
#Deactivate auto-sync
kubectl  --context hub patch applicationset appofapps -n argocd --type=json -p='[{"op": "remove", "path": "/spec/template/spec/syncPolicy"}]'

#Clean Workloads
kubectl  --context hub delete applicationset -n argocd workload --cascade=foreground
#Clean namespaces
kubectl  --context hub delete applicationset -n argocd namespace --cascade=foreground
#Clea projects
kubectl  --context hub delete applicationset -n argocd argoprojects --cascade=foreground
#Clean addons (but the have preserve On)
kubectl  --context hub delete applicationset -n argocd cluster-addons --cascade=foreground

#Clean app of apps
kubectl  --context hub delete applicationset -n argocd appofapps --cascade=foreground

