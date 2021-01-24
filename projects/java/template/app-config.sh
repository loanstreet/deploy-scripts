TYPE=java
BUILD=mvnw
FORMAT=spring-boot
RESTART_COMMAND='sh ./deploy/run.sh restart'

REPO=git@github.com-loanstreet:loanstreet/app-name.git
DEPLOYMENT_SERVER=fincon-dev.finology.com.my

DEPLOYMENT_DIR='$HOME/sites'

DEPLOYMENT_SERVER_USER=deploy
SERVICE_NAME=app-name
# LINKED_FILES="config/database.yml config/sms.yml"
LINKED_DIRS="logs"
RESOURCE_DIRS="src/main/resources"
