BUILD=java-mvnw
DEPLOYMENT_DIR='$HOME/sites'
DEPLOYMENT_SERVER=fincon-dev.finology.com.my
DEPLOYMENT_SSH_USER=deploy
SERVICE_NAME=app-name
GIT_REPO=git@github.com-loanstreet:loanstreet/app-name.git
# LINKED_FILES="config/database.yml config/sms.yml"
LINKED_DIRS="logs"


# Dependencies
# Make a list of dependency labels, then use those labels in env vars to build or prepare that dependency
DEPENDENCIES="XC_DECISION_ENGINE"
XC_DECISION_ENGINE_GIT_REPO="git@git.loanstreet.com.my:loanstreet/xc-decision-engine.git"
XC_DECISION_ENGINE_GIT_BRANCH="0.0.1"
XC_DECISION_ENGINE_BUILD_COMMAND="sh deploy/deploy.sh $PROJECT_ENVIRONMENT && ./mvnw install:install-file -Dfile=target/my.com.finology.xc.decision.engine-$XC_DECISION_ENGINE_GIT_BRANCH.jar"
