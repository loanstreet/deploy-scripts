#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))

if [ ! -f $SCRIPT_PATH/config.sh ]; then
	echo "Please initialize config.sh with vars START_COMMAND"
	exit
fi

. $SCRIPT_PATH/config.sh

if [ "$DEPLOYMENT_DIR" = "" ]; then
	DEPLOYMENT_DIR=$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT
fi

if [ "$START_COMMAND" = "" ]; then
	echo "Please supply a START_COMMAND in config.sh"
	exit
fi

if [ "$PID_PATH" = "" ]; then
	eval DEPLOYMENT_DIR=$DEPLOYMENT_DIR
	PID_PATH=$DEPLOYMENT_DIR/$SERVICE_NAME.pid

	PID_COMMAND='echo $!'
	PID_COMMAND="$PID_COMMAND > $PID_PATH"
	START_COMMAND="$START_COMMAND & $PID_COMMAND"
fi

case $1 in
	start)
		echo "Starting $SERVICE_NAME ($PROJECT_ENVIRONMENT) ..."
		if [ ! -f $PID_PATH ]; then
			sh -c "$START_COMMAND"
			PID=$(cat $PID_PATH)
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID started ..."
		else
			$PID = $(cat $PID_PATH)
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID is already running ..."
		fi
	;;
	stop)
		if [ -f $PID_PATH ]; then
			PID=$(cat $PID_PATH);
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID stopping ..."
			kill $PID;
			sleep 5 # wait to stop completely
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID stopped ..."
			if [ -f $PID_PATH ]; then
				rm $PID_PATH 2>&1 >> /dev/null
			fi
		else
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) is not running ..."
		fi
	;;
	restart)
		if [ -f $PID_PATH ]; then
			PID=$(cat $PID_PATH);
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID stopping ...";
			kill $PID;
			sleep 5 # wait to stop completely
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID stopped ...";
			if [ -f $PID_PATH ]; then
				rm $PID_PATH 2>&1 >> /dev/null
			fi
		else
			echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) is not running ..."
		fi
		echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) starting ..."
		sh -c "$START_COMMAND"
		PID=$(cat $PID_PATH)
		echo "$SERVICE_NAME ($PROJECT_ENVIRONMENT) PID: $PID started ..."
	;;
esac
