ds_format() {
	if [ "$1" = "" ]; then
		error "format: node: Too few arguments given"
	fi

	cd "$1"

	info "Preparing deployment files for packaging ... "
	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent
	if [ "$NODE_SCRIPT" = "" ]; then
		error "No node server script supplied in NODE_SCRIPT"
	fi
	COMMAND='nohup node $DEPLOYMENT_DIR/current/$NODE_SCRIPT 2>> logs/stderr.log >> logs/stdout.log'
	printf "START_COMMAND=\"$COMMAND\"\n" >> deploy-config.sh

	cat deploy-config.sh >> ./$DS_DIR/config.sh
	success 'done'
}
