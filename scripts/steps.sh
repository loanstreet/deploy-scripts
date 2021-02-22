STEPS="repo build format package push post_push"

ds_get_steps() {
	STEP_LIST=$(echo "$STEPS" | cut -d";" -f1)
	STEP_ORDER=""
	for i in $STEP_LIST; do
		STEP_VAR=$(eval echo \${BEFORE_$i})
		if [ "$STEP_VAR" != "" ]; then
			STEP_ORDER="$STEP_VAR $STEP_ORDER"
		fi
		STEP_ORDER="$STEP_ORDER $i"
		STEP_VAR=$(eval echo \$AFTER_$i)
		if [ "$STEP_VAR" != "" ]; then
			STEP_ORDER="$STEP_ORDER $STEP_VAR"
		fi
	done

	STEPS="$STEP_ORDER"
}
