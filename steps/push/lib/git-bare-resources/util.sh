ds_create_bare_repo() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "bare-repo-creation: Too few arguments given to ds_create_bare_repo"
	fi

	TIMESTAMP=$(date +%s)
	BARE_REPO_SCRIPT_DIR=/tmp/deployer-$TIMESTAMP

	mkdir -p $BARE_REPO_SCRIPT_DIR
	cp "$1/$DS_DIR/config.sh" $BARE_REPO_SCRIPT_DIR/config.sh
	cp $SCRIPT_PATH/../steps/push/lib/post-deploy/post-deploy-utils.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/../steps/push/lib/git-bare-resources/post-receive-utils.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/util.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/../steps/push/lib/git-bare-resources/bare-repo.sh $BARE_REPO_SCRIPT_DIR/

	info "Copying generic post-receive hook $2"
	cp "$2" $BARE_REPO_SCRIPT_DIR/post-receive-hook

	info "Copying scripts to create bare git repo"
	scp -o StrictHostKeyChecking=no -P$DEPLOYMENT_SERVER_PORT -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:/tmp/ 2>&1 | indent
ssh -o "StrictHostKeyChecking no" -p $DEPLOYMENT_SERVER_PORT -t $DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER << EOSSH
cd $BARE_REPO_SCRIPT_DIR && sh ./bare-repo.sh
EOSSH
}