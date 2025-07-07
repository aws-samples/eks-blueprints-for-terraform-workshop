function argocd_kill_port_forward (){
	pkill -9 -f "kubectl --context $1 port-forward svc/argocd-server -n argocd $2:80"
}

function argocd_credentials (){
    # This might not need it during workshop
	# argocd_kill_port_forward $1 $2
	argo_url
	export ARGO_CD_URL=$(kubectl --context hub-cluster get svc -n argocd  argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
	echo "ArgoCD URL: before $ARGO_CD_URL after"
	export ARGOCD_PWD=$(kubectl get secrets argocd-initial-admin-secret -n argocd --template='{{index .data.password | base64decode}}' --context $1)
    argocd login "$ARGO_CD_URL" --plaintext --username admin --password $ARGOCD_PWD --name $1
	echo "ArgoCD Username: admin"
	echo "ArgoCD Password: $ARGOCD_PWD"
	echo "ArgoCD URL: $ARGO_CD_URL"
}

function gitea_credentials (){
	echo "Gitea Username: workshop-user"
	echo "Gitea Password: $GITEA_PASSWORD"
	echo $GITEA_EXTERNAL_URL/workshop-user/	
}

function argocd_hub_credentials (){
	argocd_credentials hub-cluster 
}





