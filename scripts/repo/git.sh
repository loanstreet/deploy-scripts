ds_repo_fetch() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "repo: git: Too few arguments given to repo_fetch"
	fi
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --progress --single-branch --depth=1 --branch $GIT_BRANCH $1 $2 #2>&1 | indent
	info "Checked out $GIT_BRANCH from $1"
}