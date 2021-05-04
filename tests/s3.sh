#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


SRV_PID=$(ps -elf | grep ':37569' | grep -v grep | awk '{print $4}')
if [ "$SRV_PID" != "" ]; then
	printf "Killing old django PID: $SRV_PID ... "
	kill -9 $PUMA_PID
	success 'done'
fi
copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project

PROJECT_STEP=$(cat <<-END
ds_exec_step() {
	title "project step"
    info "Executing project demo step"
}
END
)

ENV_STEP=$(cat <<-END
ds_exec_step() {
	title "env step"
    info "Executing environment step"
}
END
)

S3_BUCKET_PATH="finology-infra/deploy-scripts/xc/production-gbsn"
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"
PROJECT_ENVIRONMENT="default"
add_project_step "$PROJECT_DEPLOY_DIR" 'step1' "$PROJECT_STEP"
add_env_step "$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT" 'step2' "$ENV_STEP"
printf "BEFORE_repo=\"step2 step1\"\nAFTER_format=\"step1 step2\"\n" >> $PROJECT_DEPLOY_DIR/app-config.sh

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
SERVICE_NAME="python-deploy-test"
DEPLOYMENT_DIR="$TEST_WORKING_DIR/$SERVICE_NAME/$PROJECT_ENVIRONMENT"
printf "\nDEPLOYMENT_DIR=$DEPLOYMENT_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=$SERVICE_NAME\nLINKED_FILES=\nLINKED_DIRS=\"venv uploads logs tmp/sockets tmp/pids\"\n" >> deploy/app-config.sh
printf "GIT_BRANCH=\nSERVICE_PORT=37569\nS3_BUCKET_PATH=$S3_BUCKET_PATH\nPACKAGE=zip\nPUSH=s3\n" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
sed -i "s/module.*$/module = django_project.wsgi:application/g" deploy/environments/$PROJECT_ENVIRONMENT/assets/uwsgi.ini
mkdir -p "deploy/environments/$PROJECT_ENVIRONMENT/scripts"
printf "ds_post() {\n    echo 'running post-package step ... '\n}\n" > "deploy/environments/$PROJECT_ENVIRONMENT/scripts/package.sh"
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
title 'TEST - check upload'
if [ "$AWS_PROFILE" = "" ]; then
	AWS_PROFILE="default"
fi
aws s3 ls "$S3_BUCKET_PATH/$SERVICE_NAME-$PROJECT_ENVIRONMENT.zip" --profile "$AWS_PROFILE"
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts
