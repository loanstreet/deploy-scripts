ds_push() {
	if [ "$1" = "" ]; then
		error "push: s3: Too few arguments given to ds_push"
	fi

	if [ "$PACKAGE" != "zip" ]; then
		error "push: s3: S3 push currently only supported with PACKAGE=zip"
	fi

	cd "$1"

	aws s3 cp ./"$SERVICE_NAME-$PROJECT_ENVIRONMENT.zip" s3://$S3_BUCKET_PATH/ --profile "$AWS_PROFILE"
}
