ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: ecs: Too few arguments given to ds_post_push"
	fi

	cd "$1"

	if [ "$ECS_CLUSTER" = "" ] || [ "$ECS_SERVICE" = "" ]; then
		error "post-push: ecs: Please set ECS_CLUSTER and ECS_SERVICE to perform post-push actions for ecs"
	fi

	info "Forcing new deployment on service $ECS_SERVICE on cluster $ECS_CLUSTER ... "
	if [ "$ECS_STOP_RUNNING_TASKS" = "true" ]; then
		TASK_LIST=$(aws ecs list-tasks --cluster "$ECS_CLUSTER" --service-name "$ECS_SERVICE" --desired-status RUNNING | sed 's/TASKARNS[[:space:]]*//g')
		for k in $TASK_LIST; do
			info "Stopping task $k on $ECS_CLUSTER ... "
			aws ecs stop-task --cluster "$ECS_CLUSTER" --task "$k"
			success "ok"
		done
	fi
	aws ecs update-service --service "$ECS_SERVICE" --cluster "$ECS_CLUSTER" --force-new-deployment
	success "done"
}