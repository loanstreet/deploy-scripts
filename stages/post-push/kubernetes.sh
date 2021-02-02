ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: kubernetes: Too few arguments given to ds_post_push"
	fi

	if [ "$KUBE_CONFIG" = "" ]; then
		KUBE_CONFIG="$1/../repo/$INSTALL_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/config.yaml"
	fi

	if [ ! -f "$KUBE_CONFIG" ]; then
		error "No kube config found at $KUBE_CONFIG"
	else
		export KUBECONFIG="$KUBE_CONFIG"
	fi


}