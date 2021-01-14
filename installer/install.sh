#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh

cd $SCRIPT_PATH/../project-templates/
PROJECT_TYPES=$(ls -d *)
cd $SCRIPT_PATH/../

if [ ! -d "$2" ]; then
	error "No such directory: $2"
fi

DEPLOY_DIR=""

UNSUPPORTED=1
for i in $PROJECT_TYPES; do
	if [ "$1" = "$i" ]; then
		UNSUPPORTED=0
		break
	fi
done

if [ $UNSUPPORTED -eq 1 ]; then
	error "Project type $1 is unsupported"
fi

DEPLOY_DIR="$2/deploy"

if [ -f "$SCRIPT_PATH/../project-templates/$1/installer/config.sh" ]; then
	. $SCRIPT_PATH/../project-templates/$1/installer/config.sh
	if [ "$INSTALL_DIR" != "" ]; then
		DEPLOY_DIR="$2/$INSTALL_DIR"
	fi
fi

printf "\nCopying deployment files to $DEPLOY_DIR ... "
mkdir -p $DEPLOY_DIR
cat << 'EOF' > $DEPLOY_DIR/deploy.sh
#!/bin/sh

DEPLOY_SCRIPTS_GIT_REPO=git@git.finology.com.my:loanstreet/deploy-scripts.git
DEPLOY_SCRIPTS_GIT_BRANCH="ver_0.3"
DEPLOY_SCRIPTS_HOME="$HOME/.deploy-scripts-$DEPLOY_SCRIPTS_GIT_BRANCH"
SCRIPT_PATH=$(dirname $(readlink -f $0))

if [ ! -d $DEPLOY_SCRIPTS_HOME ]; then
	echo "Downloading deploy-scripts"
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone $DEPLOY_SCRIPTS_GIT_REPO $DEPLOY_SCRIPTS_HOME
fi
cd $DEPLOY_SCRIPTS_HOME && git fetch origin +refs/heads/$DEPLOY_SCRIPTS_GIT_BRANCH && git checkout $DEPLOY_SCRIPTS_GIT_BRANCH && cd $SCRIPT_PATH
PROJECT_DEPLOY_DIR=$SCRIPT_PATH sh $DEPLOY_SCRIPTS_HOME/deploy.sh $1
EOF

cp -r -n $SCRIPT_PATH/../project-templates/$1/* $DEPLOY_DIR/
rm -rf $DEPLOY_DIR/installer

success "done"

if [ "$3" = "--no-post-install" ]; then
	exit
fi

line
info "Please edit the variables in app-config.sh to suit your deployment\n"
info "A sample environment named 'default' has been copied to $DEPLOY_DIR"
info "Please rename it to your desired environment (eg. staging) name and edit the config.sh"
info "within the folder according to your deployment settings\n"
info "Once you have made the edits, you can deploy by executing the 'deploy.sh' script"
info "from your project directory. For example:\n"
info "\tsh $DEPLOY_DIR/deploy.sh staging"

if [ -f "$SCRIPT_PATH/../project-templates/$1/installer/post_install.sh" ]; then
	echo "\n"
	sh "$SCRIPT_PATH/../project-templates/$1/installer/post_install.sh"
fi

line
