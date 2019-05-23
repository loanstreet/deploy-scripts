create_symlinks() {
	mkdir -p $DEPLOY_DIR/shared
	cd $DEPLOY_DIR/current
	if [ "$LINKED_DIRS" != "" ]; then
        	LINK_DIRS=$(echo "$LINKED_DIRS" | cut -d";" -f1)
	        for i in $LINK_DIRS; do
        	        mkdir -p $DEPLOY_DIR/shared/$i
			printf "Creating symlink $i -> $DEPLOY_DIR/shared/$i ... "
                	ln -sf $DEPLOY_DIR/shared/$i $i
			echo "done"
	        done
	fi
	if [ "$LINKED_FILES" != "" ]; then
        	LINK_FILES=$(echo "$LINKED_FILES" | cut -d";" -f1)
	        for j in $LINK_FILES; do
			cd $DEPLOY_DIR/shared
			DIR=$(dirname $j)
			mkdir -p $DIR
			cd $DEPLOY_DIR/current
			printf "Creating symlink $j -> $DEPLOY_DIR/shared/$j ... "
                	ln -s $DEPLOY_DIR/shared/$j $j
			echo "done"
			if [ ! -f $DEPLOY_DIR/shared/$j ]; then
				echo "Shared file $j does not exist. Please create it manually."
			fi
	        done
	fi
}
