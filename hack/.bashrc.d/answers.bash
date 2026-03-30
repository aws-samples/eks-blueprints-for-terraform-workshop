
function argocd_url (){
	aws eks describe-capability --cluster-name argocd-hub --capability-name argocd --query 'capability.configuration.argoCd.serverUrl' --output text
}

function gitlab_url (){
	echo "https://$(aws elbv2 describe-load-balancers --names gitlab-nlb --query 'LoadBalancers[0].DNSName' --output text)"
}

function app_url_dev (){
  wait-for-lb $(kubectl  get svc -n ui team-retail-store-deployment-ui-dev-nlb  --context dev  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}


function app_url_prod (){
  wait-for-lb $(kubectl --context prod  get svc -n ui team-retail-store-deployment-ui-prod-nlb  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}

function codeconnection_url (){
  ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  CONNECTION_ARN=$(aws codeconnections list-connections --query 'Connections[?ConnectionStatus==`AVAILABLE`].ConnectionArn | [0]' --output text)
  CONNECTION_ID=$(echo $CONNECTION_ARN | awk -F'/' '{print $NF}')
  REGION=$(echo $CONNECTION_ARN | awk -F':' '{print $4}')
  echo "https://codeconnections.${REGION}.amazonaws.com/git-http/${ACCOUNT_ID}/${REGION}/${CONNECTION_ID}/gitlab/guestbook.git"
}







