ds_create_dir_structure() {
	if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
		error "installer: create dirs: Insufficient args given to ds_create_dir_structure"
	fi

	DEPLOY_DIR="$1/$2"

	if [ -d "$DEPLOY_DIR" ]; then
		warning "Found existing $DEPLOY_DIR in project!"
		rm -rf "$DEPLOY_DIR.old"
		infof "Moving existing $DEPLOY_DIR to $DEPLOY_DIR.old ... "
		mv "$DEPLOY_DIR" "$DEPLOY_DIR.old"
		success "done"
	fi

	ENV_DIR="$DEPLOY_DIR/environments/$INSTALL_ENV"
	infof "Creating $DEPLOY_DIR ... "
	mkdir -p $DEPLOY_DIR
	success "done"

	infof "Creating $ENV_DIR/assets ... "
	mkdir -p "$ENV_DIR/assets"
	success "done"

	APP_CONFIG="$DEPLOY_DIR/app-config.sh"
	infof "Creating $APP_CONFIG ... "
	printf "TYPE=$3\nSERVICE_NAME=example.com\nREPO=git@github.com:namespace/app.git\nDEPLOYMENT_SERVER=example.com\nDEPLOYMENT_SERVER_USER=deploy\nRESTART_COMMAND=\"sh $DS_DIR/run.sh restart\"\n" >> "$APP_CONFIG"
	success "done"
	ENV_CONFIG="$ENV_DIR/config.sh"
	infof "Creating $ENV_CONFIG ... "
	printf "GIT_BRANCH=master\n" >> "$ENV_CONFIG"
	success "done"
}

ds_install_docker() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "installer: docker: Insufficient args given to ds_install_docker"
	fi
	DOCKER_PROJECT="$1/$DS_DIR/docker"
	infof "Creating $DOCKER_PROJECT ... "
	mkdir -p "$DOCKER_PROJECT"
	success "done"
	FROM_IMAGE="$2:latest"
	if [ "$DOCKER_IMAGE" != "" ]; then
		FROM_IMAGE="$DOCKER_IMAGE"
	fi
	DOCKERFILE_PATH="$DOCKER_PROJECT/Dockerfile"
	infof "Creating $DOCKERFILE_PATH ... "
	printf "FROM $FROM_IMAGE\n\nEXPOSE 80\n" > "$DOCKERFILE_PATH"
	success "done"

	DOCKER_COMPOSE=$(cat <<-END
version: '3'

services:
  default:
    image: example-$INSTALL_ENV:latest
    restart: always
    build:
      context: .
      dockerfile: Dockerfile
      args:
        APP_ENV: $INSTALL_ENV
    ports:
      - 3000:80
END
	)

	DOCKER_COMPOSE_PATH="$DOCKER_PROJECT/docker-compose.yml"
	infof "Creating $DOCKER_COMPOSE_PATH ... "
	printf "$DOCKER_COMPOSE" > "$DOCKER_COMPOSE_PATH"
	success "done"

	infof "Adding docker vars to app-config.sh and $INSTALL_ENV/config.sh ... "
	printf "DOCKER_REGISTRY=https://index.docker.io\n" >> "$1/$DS_DIR/app-config.sh"
	printf "PACKAGE=docker\nPUSH=\"\"\n" >> "$1/$DS_DIR/environments/$INSTALL_ENV/config.sh"
	success "done"
}

ds_install_kubernetes() {
	if [ "$1" = "" ]; then
		error "installer: kubernetes: Insufficient args given to ds_install_kubernetes"
	fi

	infof "Adding kubernetes vars to $INSTALL_ENV/config.sh ... "
	TLS_SECRET="$INSTALL_ENV-$(date '+%s')"
	printf "# POST_PUSH=kubernetes\n# KUBERNETES_CLUSTER='dev'\n# KUBERNETES_INGRESS='ingress-dev'\n# KUBERNETES_TLS=false\n# KUBERNETES_CERT_MANAGER=letsencrypt-prod\n" >> "$1/$DS_DIR/environments/$INSTALL_ENV/config.sh"
	success "done"
}
