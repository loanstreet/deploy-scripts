ds_build() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "build: mvnw: Too few arguments given"
	fi
	cd "$1"
	sh -c "$MAVEN_BIN package -Dmaven.test.skip=true 2>&1" | indent
	cd target/
	WARFILE=$(ls *.war | head -n1)
	if [ "$WARFILE" = "" ]; then
		WARFILE=$(ls *.jar | head -n1)
	fi
	if [ "$WARFILE" = "" ]; then
		error "build: mvnw: No jar or war file could be built"
	fi
	if [ ! -d "$2" ]; then
		error "build: mvnw: No package directory available to place warfile"
	fi
	cp "$WARFILE" "$2/"
	printf "WARFILE=$WARFILE\n" >> "$2/deploy-config.sh"
}
