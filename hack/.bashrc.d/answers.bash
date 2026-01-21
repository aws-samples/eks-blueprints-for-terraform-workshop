function deploy_prod (){
  # Deploy the production cluster

  # Create the production cluster
  mkdir $GITOPS_DIR/fleet/members/fleet-spoke-prod
  cp $WORKSHOP_DIR/gitops/solutions/module-platform/fleet/members/fleet-spoke-prod/values.yaml $GITOPS_DIR/fleet/members/fleet-spoke-prod/values.yaml
  git -C $GITOPS_DIR/fleet status
  git -C $GITOPS_DIR/fleet add .
  git -C $GITOPS_DIR/fleet commit -m "add production cluster fleet member"
  git -C $GITOPS_DIR/fleet push

  # Deploy the production addons
  mkdir $GITOPS_DIR/addons/clusters/fleet-spoke-prod
  cp -r $WORKSHOP_DIR/gitops/solutions/module-platform/addons/clusters/fleet-spoke-prod/* $GITOPS_DIR/addons/clusters/fleet-spoke-prod/
  git -C $GITOPS_DIR/addons status
  git -C $GITOPS_DIR/addons add .
  git -C $GITOPS_DIR/addons commit -m "add addons for production cluster"
  git -C $GITOPS_DIR/addons push

  # Deploy the production namespaces
  cp -r $WORKSHOP_DIR/gitops/solutions/module-platform/platform/teams/* $GITOPS_DIR/platform/teams/
  git -C $GITOPS_DIR/platform status
  git -C $GITOPS_DIR/platform add .
  git -C $GITOPS_DIR/platform commit -m "add production namespaces for teams"
  git -C $GITOPS_DIR/platform push

  # Deploy the production apps
  cp -r $WORKSHOP_DIR/gitops/solutions/module-platform/apps/* $GITOPS_DIR/apps/
  git -C $GITOPS_DIR/apps status
  git -C $GITOPS_DIR/apps add .
  git -C $GITOPS_DIR/apps commit -m "add production kustomize files for apps"
  git -C $GITOPS_DIR/apps push
}

function argocd_url (){
	aws eks describe-capability --cluster-name argocd-hub --capability-name argocd --query 'capability.configuration.argoCd.serverUrl' --output text
}

function app_url_dev (){
  wait-for-lb $(kubectl  get svc -n ui team-retail-store-deployment-ui-dev-nlb  --context dev  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}


function app_url_prod (){
  wait-for-lb $(kubectl --context prod  get svc -n ui team-retail-store-deployment-ui-prod-nlb  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}







