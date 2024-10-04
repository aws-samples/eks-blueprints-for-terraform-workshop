#!/bin/bash

set -uo pipefail


#Activate AutoSync
#kubectl  --context hub-cluster patch applicationset bootstrap -n argocd --type=json -p='[{"op": "add", "path": "/spec/template/spec/syncPolicy", "value": {"automated": {"prune": true, "selfHeal": true}}}]'
#Deactivate auto-sync
kubectl  --context hub-cluster patch applicationset bootstrap -n argocd --type=json -p='[{"op": "remove", "path": "/spec/template/spec/syncPolicy"}]'

#Clean Workloads
kubectl  --context hub-cluster delete applicationset -n argocd workload --cascade=foreground
#Clean namespaces
kubectl  --context hub-cluster delete applicationset -n argocd namespace --cascade=foreground
#Clea projects
kubectl  --context hub-cluster delete applicationset -n argocd argoprojects --cascade=foreground
#Clean addons (but the have preserve On)
kubectl  --context hub-cluster delete applicationset -n argocd cluster-addons --cascade=foreground

#Clean app of apps
<<<<<<< Updated upstream
kubectl  --context hub-cluster delete applicationset -n argocd appofapps --cascade=foreground
=======
kubectl  --context hub-cluster delete applicationset -n argocd bootstrap --cascade=foreground
>>>>>>> Stashed changes

