ds_kube_ingress_nginx() {
	if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
		error "post-push: kubernetes: ingress-nginx: Too few arguments given to ds_kube_ingress_nginx"
	fi

	NGINX_SITES="$KUBERNETES_HOME/sites/$KUBERNETES_CLUSTER"
	if [ ! -d "$NGINX_SITES" ]; then
		mkdir -p "$NGINX_SITES"
	fi

	TIMESTAMP=$(date '+%s')
	KUBERNETES_NGINX_CONFIG="$KUBERNETES_HOME/$KUBERNETES_CLUSTER-ingress-nginx-$TIMESTAMP.yaml"
	cp "$SCRIPT_PATH/../stages/post-push/kubernetes-resources/ingress-nginx.yaml" "$KUBERNETES_NGINX_CONFIG"
	if [ "$KUBERNETES_CERT_MANAGER" != "" ]; then
		echo "    cert-manager.io/cluster-issuer: \"$KUBERNETES_CERT_MANAGER\"" >> "$KUBERNETES_NGINX_CONFIG"
	fi
	echo "spec:\n  rules:" >> "$KUBERNETES_NGINX_CONFIG"

	HOST_CFG=$(cat <<-END
    - host: $1
      http:
        paths:
          - backend:
              serviceName: $2
              servicePort: $3
END
	)

	HOST_FILE="$NGINX_SITES/$1"
	if [ "$KUBERNETES_TLS" = "true" ]; then
		if [ -f "$HOST_FILE" ]; then
			rm -f $HOST_FILE
		fi
		HOST_FILE="$NGINX_SITES/tls_$1"
	fi
	echo "$HOST_CFG" > "$HOST_FILE"

	TLS_HOSTS=""
	SITES=$(ls $NGINX_SITES/)
	for i in $SITES; do
		TLS=$(echo $i | cut -c -4)
		if [ "$TLS" = "tls_" ]; then
			TLS_HOST=$(echo $i | cut -d_ -f2)
			TLS_HOSTS="$TLS_HOSTS $TLS_HOST"
		fi
		cat "$HOST_FILE" >> "$KUBERNETES_NGINX_CONFIG"
	done

	debug "TLS Hosts: $TLS_HOSTS"

	if [ "$TLS_HOSTS" != "" ]; then
		echo "\n  tls:\n    - hosts:" >> "$KUBERNETES_NGINX_CONFIG"
		TLS_LIST=$(echo "$TLS_HOSTS" | cut -d";" -f1)
		for j in $TLS_LIST; do
			echo "      - $j" >> "$KUBERNETES_NGINX_CONFIG"
		done
		echo "      secretName: ingress-tls" >> "$KUBERNETES_NGINX_CONFIG"
	fi

	ds_debug_cat "$KUBERNETES_NGINX_CONFIG"
	# yamllint "$KUBERNETES_NGINX_CONFIG"

	if [ "$?" = "0" ]; then
		kubectl apply -f "$KUBERNETES_NGINX_CONFIG"
		info "Applied ingress-nginx config"
	else
		error "Error encountered while generating ingress-nginx config"
	fi
	rm -f "$KUBERNETES_NGINX_CONFIG"
}

ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: kubernetes: Too few arguments given to ds_post_push"
	fi

	cd "$1"
	if [ "$KUBERNETES_CLUSTER" = "" ]; then
		error "post-push: kubernetes: no KUBERNETES_CLUSTER value set"
	fi

	if [ "$KUBERNETES_CLUSTER_CONFIG" = "" ]; then
		KUBERNETES_CLUSTER_CONFIG="$KUBERNETES_HOME/$KUBERNETES_CLUSTER.yaml"
	fi

	export KUBECONFIG="$KUBERNETES_CLUSTER_CONFIG"
	ds_debug_exec "kubectl version --client"

	TAG=$(grep 'image:' docker-compose.yml | awk '{print $2}')

	if [ "$TAG" = "" ]; then
		error "post-push: kubernetes: Failed to look up tag in docker-compose.yml"
	fi

	KUBE_SERVICE="$SERVICE_NAME-$PROJECT_ENVIRONMENT"

	EXISTING_SERVICE=$(kubectl get services | grep "$KUBE_SERVICE" | wc -l)
	if [ $EXISTING_SERVICE -eq 0 ]; then
		KUBE_SERVICE_CFG="$1/../repo/$INSTALL_DIR/environments/$PROJECT_ENVIRONMENT/kubernetes/service.yaml"

		if [ ! -f "$KUBE_SERVICE_CFG" ]; then
			warning "post-push: kubernetes: No service config found at $KUBE_SERVICE_CFG. Generating from template"
			if [ "$DOCKER_REGISTRY" = "" ]; then
				error "post-push: kubernetes: Auto k8s service generation currently depends on DOCKER_REGISTRY being set"
			fi

			DOCKER_HOST=$(echo "$DOCKER_REGISTRY" | awk -F / '{print $3}')
			KUBE_MANIFESTS_DIR="$1/kube-manifests"
			mkdir -p "$KUBE_MANIFESTS_DIR"
			cp "$DEPLOY_SCRIPTS_DIR/stages/post-push/kubernetes-resources/service.yaml" "$KUBE_MANIFESTS_DIR"
			KUBE_SVC_FILE="$KUBE_MANIFESTS_DIR/service.yaml"

			debug "$KUBE_SVC_FILE"

			sed -i "s/name:.*$/name: $KUBE_SERVICE/g" "$KUBE_SVC_FILE"
			sed -i "s/app:.*$/app: $KUBE_SERVICE/g" "$KUBE_SVC_FILE"
			sed -i "s/image:.*$/image: $DOCKER_HOST\/$TAG/g" "$KUBE_SVC_FILE"

			if [ "$KUBERNETES_REPLICAS" != "" ]; then
				sed -i "s/replicas:.*$/replicas: $KUBERNETES_REPLICAS/g" "$KUBE_SVC_FILE"
			fi

			if [ "$KUBERNETES_CRED" != "" ]; then
				echo "      imagePullSecrets:\n        - name: $KUBERNETES_CRED" >> "$KUBE_SVC_FILE"
			fi

			ds_debug_cat "$KUBE_SVC_FILE"

			yamllint "$KUBE_SVC_FILE"

			KUBE_SERVICE_CFG="$KUBE_SVC_FILE"
		fi

		kubectl create -f "$KUBE_SERVICE_CFG"
	else
		info "Kubernetes service $KUBE_SERVICE exists. Applying new image"
		debug "Setting new image for kube deployment"
		kubectl set image deployment $KUBE_SERVICE $KUBE_SERVICE=$TAG
	fi

	if [ "$KUBERNETES_NGINX_SERVICE_HOST" = "" ]; then
		KUBERNETES_NGINX_SERVICE_HOST="$SERVICE_NAME"
	fi


	if [ "$KUBERNETES_NGINX" = "true" ]; then
		if [ "$KUBERNETES_NGINX_SERVICE_PORT" = "" ]; then
			KUBERNETES_NGINX_SERVICE_PORT="80"
		fi
		ds_kube_ingress_nginx "$KUBERNETES_NGINX_SERVICE_HOST" "$KUBE_SERVICE" "$KUBERNETES_NGINX_SERVICE_PORT"
	fi
}
