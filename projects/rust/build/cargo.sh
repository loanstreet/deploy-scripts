ds_build() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "build: cargo: Too few arguments given"
	fi
	cd "$1"
	cargo install --path . --root "$2"
	cd "$2/bin"
	BINPATH=$(ls * | head -n1)
	if [ "$BINPATH" = "" ]; then
		error "build: cargo: No binary could be built"
	fi
	printf "BINPATH=$BINPATH\n" >> "$2/deploy-config.sh"
}
