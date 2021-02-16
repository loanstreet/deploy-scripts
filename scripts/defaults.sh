DS_DIR="deploy"
DS_USER_DEFAULTS="$HOME/.config/deploy-scripts-defaults.sh"
DS_UPDATE=true
DEPLOYMENT_SERVER_PORT=22
DEPLOYMENT_SERVER_PROTOCOL=ssh
DEPLOYMENT_SERVER_USER=deploy
REPO_TYPE=git
PUSH=git-bare
PACKAGE=git
RESTART_COMMAND="sh deploy/run.sh restart"
DEPLOYMENT_DIR='$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT'
RELEASE_COUNT=5
DOCKER_COMPOSE_OPTS=""
DOCKER_REGISTRY=https://dockerhub.finology.com.my
KUBERNETES_CRED="fincred"
KUBERNETES_HOME="$HOME/.kube"
KUBERNETES_CLUSTER="dev"
KUBERNETES_INGRESS="ingress-dev"
KUBERNETES_TLS="false"
KUBERNETES_REPLICAS="1"
KUBERNETES_CERT_MANAGER="letsencrypt-staging"

# Load vars to override from deploy-scripts-defaults.sh if available
if [ -f "$DS_USER_DEFAULTS" ]; then
	. "$DS_USER_DEFAULTS"
fi
