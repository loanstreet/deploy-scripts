ds_build() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "build: npm: Too few arguments given"
	fi
	if [ ! -d "$2" ]; then
		error "build: npm: No package directory available to place warfile"
	fi
	cd "$1"

	ENV_JS_PATH="$1/../repo/$DS_DIR/environments/$PROJECT_ENVIRONMENT/env.js"
	if [ ! -f "$ENV_JS_PATH" ]; then
		if [ "$REACTJS_ENVJS_PATH" != "" ]; then
			CHECK_ABS_PATH=$(echo $REACTJS_ENVJS_PATH | cut -c -1)
			if [ "$CHECK_ABS_PATH" = "/" ]; then
				ENV_JS_PATH="$REACTJS_ENVJS_PATH"
			else
				ENV_JS_PATH="$1/../repo/$DS_DIR/$REACTJS_ENVJS_PATH"
			fi
		fi
	fi
	if [ ! -f "$ENV_JS_PATH" ]; then
		warning "No env.js found at $ENV_JS_PATH. Building without it"
	else
		ln -s "$ENV_JS_PATH" src/_config/env.js
	fi

	if [ "$NPM_PREFIX" != "" ]; then
		mkdir -p $NPM_PREFIX && ln -sf $NPM_PREFIX node_modules && npm install
	else
		npm install
	fi
	npm run build
	if [ -d "./build" ]; then
		cp -r ./build/* "$2/"
	elif [ -d "./dist" ]; then
		cp -r ./dist/* "$2/"
	else
		error "NPM output directory not found under either build/ or dist/"
	fi
}