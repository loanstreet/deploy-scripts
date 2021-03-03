ds_post_push() {
	if [ "$1" = "" ]; then
		error "post-push: ecs: Too few arguments given to ds_post_push"
	fi

	cd "$1"

	if [ "$ECS_CLUSTER" = "" ] || [ "$ECS_SERVICE" = "" ]; then
		error "post-push: ecs: Please set ECS_CLUSTER and ECS_SERVICE to perform post-push actions for ecs"
	fi

	aws ecs update-service --service "$ECS_SERVICE" --cluster "$ECS_CLUSTER" --force-new-deployment
}