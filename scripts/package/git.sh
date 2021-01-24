ds_package() {
	if [ "$1" = "" ]; then
		error "package: spring-boot: java: Too few arguments given"
	fi

	cd "$1"
	git init 2>&1 | indent
	git config user.name "deployer"
	git config user.email "techgroup@loanstreet.com.my"
	git add . 2>&1 | indent
	git commit . -m "push for deployment" 2>&1 | indent

	if [ -d $PROJECT_SCRIPTS_DIR ]; then
		cp -r $PROJECT_SCRIPTS_DIR "$1/deploy"
		cd "$1"
		git add deploy/scripts 2>&1 | indent
		git commit . -m "added project scripts to server side deployment" 2>&1 | indent
		info "Copied project deployment scripts to server side deployment"
	fi

	DEPLOY_BRANCH="master"
}