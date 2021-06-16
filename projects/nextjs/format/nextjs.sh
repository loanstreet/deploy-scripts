ds_format() {
	if [ "$1" = "" ]; then
		error "format: nextjs: Too few arguments given"
	fi

	cd "$1"

	info "Preparing deployment files for packaging ... "
	git --work-tree=./ --git-dir=../repo/.git checkout -f 2>&1 | indent
	success 'done'
}
