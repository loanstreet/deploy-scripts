ds_build() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "build: mvnw: Too few arguments given"
	fi
	if [ ! -d "$2" ]; then
		error "build: mvnw: No package directory available to place warfile"
	fi
	cd "$1"

	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent

	ENV_JS_PATH="$1/../repo/$INSTALL_DIR/environments/$PROJECT_ENVIRONMENT/env.js"
	if [ ! -f "$ENV_JS_PATH" ]; then
		if [ "$REACTJS_ENVJS_PATH" = "" ]; then
			error "No env.js supplied, which is needed when building locally"
		else
			CHECK_ABS_PATH=$(echo $REACTJS_ENVJS_PATH | cut -c -1)
			if [ "$CHECK_ABS_PATH" = "/" ]; then
				ENV_JS_PATH = "$REACTJS_ENVJS_PATH"
			else
				ENV_JS_PATH = "$1/../repo/$INSTALL_DIR/$REACTJS_ENVJS_PATH"
			fi
		fi
	fi
	if [ ! -f "$ENV_JS_PATH" ]; then
		error "No env.js found at $ENV_JS_PATH"
	fi
	ln -s "$ENV_JS_PATH" src/_config/env.js
	if [ "$NPM_PREFIX" != "" ]; then
		mkdir -p $NPM_PREFIX && ln -sf $NPM_PREFIX node_modules && npm install
	else
		npm install
	fi
	npm run build
	cp -r ./build/* "$2/"
}