# deploy-scripts

1. [Demo](#demo)
2. [Overview](#overview)
3. [Installation](#installation)
4. [Adding deployment to a project](#adding-deployment-to-a-project)
5. [Sample Deployment](#sample-deployment)
6. [Deployment Steps](#deployment-steps)
7. [Automated Testing](#automated-testing)
8. [Licence](#licence)
9. [Customizing build steps](#customizing-build-steps)
10. [Configuration Variables](#configuration-variables)

# Demo

### In action

[Example of the project in action](https://ci.ayravat.com/ritesh/gemini-git-browser)

### Screenshot

![Screenshot of a deployment](https://infra.finology.com.my/deploy-scripts-sample.png)

# Overview

deploy-scripts is a collection of shell scripts to automate the packaging and deployment of projects.

It works similarly to capistrano, but has fewer dependencies.

Apart from the build dependencies of the project you are tying to deploy, it should only need the following dependencies:

```bash
- git               # Currently only works with git repos
- /bin/sh           # A Bourne-like shell found on most unix-like systems
- openssh-client    # An SSH client to connect with remote machines where the software will be deployed
- docker            # (Optional) The docker command line tools in case the project uses docker
- docker-compose    # (Optional) The docker-compose tool to build images in case the project uses docker
- kubectl           # (Optional) The kubectl command line tool in case the project works with kubernetes
- aws-cli           # (Optional) The AWS command line tool (version <2) in case the project deploys to AWS ECS
```

The project is still under heavy development and is being updated to include support for other tools.

As much as possible, any new code added to this project should be able to run in a POSIX shell. Exceptions can be made depending on the project you are deploying (eg. bash is ok to use with rails specific parts because a lot of rails related tools need bash anyway).

The following stacks are currently supported

- Java lib projects and Spring Boot (with Maven Wrapper used for building the jar file)
- Ruby on Rails
- Django
- React JS
- Node JS
- Next JS
- PHP
- actix-web (rust web framework)
- Static HTML

Support has also been added to containerize and deploy projects built on the above stacks with:

- Docker
- Kubernetes
- Amazon ECS

# Installation

deploy-scripts can be installed in any one of the following 2 ways

### Git checkout

Just make a git checkout of the stable branch to your home directory with the following command.

```bash
git clone --single-branch --branch 0.6.0 https://github.com/loanstreet/deploy-scripts.git $HOME/.deploy-scripts/0.6.0
```

### Bootstrap script for docker image

Or download a bootstrap script that will use a dockerized version of deploy-scripts to manage your deployments.
You can save the script to one of the directories in your PATH environment variable for easy execution

```bash
# To just download as a shell script
curl https://raw.githubusercontent.com/loanstreet/deploy-scripts/0.6.0/deploy-scripts.sh -o $HOME/deploy.sh

# To download the script and update your PATH variable for easy execution
mkdir -p $HOME/.deploy-scripts \
	&& curl https://raw.githubusercontent.com/loanstreet/deploy-scripts/0.6.0/deploy-scripts.sh -o $HOME/.deploy-scripts/deploy \
	&& chmod +x $HOME/.deploy-scripts/deploy \
	&& echo 'PATH="$HOME/.deploy-scripts:$PATH"' >> ~/.profile \
	&& . ~/.profile
```

# Adding deployment to a project

Deployment support can be added to a project with the following commands

### Git checkout installation

If you have installed deploy-scripts with the [git checkout method](#git-checkout) mentioned above, you can install the required files to your project directory with the following commands.

```bash
cd $HOME/.deploy-scripts/0.6.0/installer

# The installer script usage is
# sh install.sh [project type] [your project directory]
# For example:
# For a Java Maven (mvnw) Project
sh install.sh java /path/to/java/project

# or for a Rails project
sh install.sh rails /path/to/rails/project

# or for a Django project
sh install.sh python /path/to/django/project

# or for an actix-web project
sh install.sh rust /path/to/actix/project

# or for a reactjs project
sh install.sh reactjs /path/to/reactjs/project

# or for a nextjs project
sh install.sh nextjs /path/to/nextjs/project

# or for a node project
sh install.sh node /path/to/node/project

# or for a simple PHP or static HTML site
sh install.sh html /path/to/project
```

### Docker image installation

If you have installed deploy-scripts as a [docker image](#bootstrap-script-for-docker-image) as mentioned above, you can install the required files to your project directory with the following commands.

```bash
# The installer command usage is
# sh deploy-scripts.sh --install [project type] [your project directory]
# For example:
# For a Java Maven (mvnw) Project
deploy --install java /path/to/java/project

# or for a Rails project
deploy --install rails /path/to/rails/project

# or for a Django project
deploy --install python /path/to/django/project

# or for an actix-web project
deploy --install rust /path/to/django/project

# or for a reactjs project
deploy --install reactjs /path/to/reactjs/project

# or for a nextjs project
deploy --install nextjs /path/to/nextjs/project

# or for a node project
deploy --install node /path/to/node/project

# or for a simple PHP or static HTML site
deploy --install html /path/to/project
```

Follow the instructions given by the installer, if any.

Once the configuration files have been added, you can further configure your deployment by modifying the [configuration variables](#configuration-variables) in `app-config.sh` or the environment-specific `config.sh`.

To start deploying according to your configured settings, go to your project root and run the following command:

```bash
# For deploy-scripts installed via git checkout
# Usage: sh deploy/deploy.sh [environment name]
# For example for the environment called 'development'
sh deploy/deploy.sh development

# For deploy-scripts installed via docker
# Usage: sh deploy-scripts.sh [your project directory] [environment name]
# For example, for deploying the environment named 'development'
deploy /my/project development
```

## Sample Deployment

For a step-by-step understanding of how a deployment happens, and how to add deployment support to a project, please check the [Sample Django Deployment](https://github.com/loanstreet/deploy-scripts/wiki/Sample-Django-Deployment) wiki page.

## Deployment Steps

- Once added to a project, deploy-scripts copies over the following files:

```bash
- / 	# project root
	- /deploy	# the directory where deploy-scripts config files are added (/config/deploy-scripts in rails)
		- app-config.sh	# Project-wide varibles for deployment configuration
		- /environments # multiple environments for the project
			- /default  # an example environment called default, this can be replaced with your own project environments
				- config.sh # environment specific config, values in which can override the ones in app-config.sh
				- /assets # files placed here are copied to the server side deployment, dir structure is maintained
#				 - /docker # (optional) environment specific docker files, can override project-wide files
#					- Dockerfile # (optional) if present, will override the one in deploy/docker
#					- docker-compose.yml # (optional) if present, will override the one in deploy/docker
#				 - /kubernetes # (optional) kubernetes configs
#					- service.yaml # (optional) config for kubernetes service and deployment for the project
#		- /scripts # (optional) Hook scripts that can be used for pre and post build hooks of each deployment step
#			- repo.sh # (optional) example of a pre and post repo checkout hook file
#		- /docker # (optional) project-wide docker files
#			- Dockerfile # (optional) if present, will be used to build the docker image
#			- docker-compose.yml # (optional) if present, will be used to build/start the container
```

It can also use the commented out optional files that are listed, but will work without them for non-containerized deployments.

All projects must have the following vars defined (in app-config.sh or config.sh) so that the relevant steps are executed.

```bash
# The project type. Currently supported options are: java, rails, python, node, reactjs and nextjs
TYPE=rails
# The name that will be used to label the app that is being deployed, commonly the hostname where the service is made available is used
SERVICE_NAME=service.com
```

A typical deployment then proceeds in a number of steps, as follows. Some steps are optional. The expectation is that each of these steps should support several options which can be combined for different types of deployments. The number and order of steps can be varied and removal or addition of more steps to the build process can be done through [Customizing build steps](#customizing-build-steps)

### List of steps
1. [Repo Checkout](#repo-checkout)
2. [Build (optional)](#build)
3. [Format (optional)](#format)
4. [Package](#package)
5. [Push (optional)](#push)
6. [Post-push (optional)](#post-push)

### Repo Checkout

The desired branch is cloned or checked out into a working directory (deploy/.build/repo by default) and the deployment is done from that checkout.

Currently only git repos are supported.

Variables:

```bash
# The repository to clone
REPO=git@github.com:namespace/repo.git
# The branch to deploy. Typically set per environment in the corresponding config.sh
GIT_BRANCH=default
```

### Build

Optional. In this step, the code may be compiled if needed, to produce the files that will be deployed.

Variables:

```bash
# The tool that will build the project. It varies by the project type (set by the TYPE variable)
BUILD=mvnw
```

### Format

Optional. The files to be deployed are assembled in the required structure to be sent to the target server. By default it's done in the deploy/.build/package directory.

Variables:

```bash
# The tool that will assemble the files for deployment. It varies by the project type (set by the TYPE variable)
FORMAT=rails
```

### Package

The assembled files in deploy/.build/package are then put into a packaged form that can be delivered to the server. The most common form we use is a new git repo, which is pushed to the target server (or another git repo), but it can take options to package it as a container as well

Variables:

```bash
# How to package the files to be deployed to be sent to the server
PACKAGE=git
```

### Push

Optional. The packaged files can then be sent to the deployment server in a number of ways. The default one is a bare git repo on the server that will receive the files and run a **post-receive** hook to deliver it to the deployment directory.

```bash
# The method used to push the packaged files
PUSH=git-bare
# The target server (can also be a git repo URL)
DEPLOYMENT_SERVER=service.com
# Credentials used when pushing with git
DEPLOYMENT_SERVER_USER=user
# The SSH port being used in case of a git push
DEPLOYMENT_SERVER_PORT=22
```

### Post-Push

Optional. Sometimes (currently only in the case of kubernetes, ecs, or deploying a docker image from a registry), you need to perform some actions to update the deployment with the new version from the machine you are deploying from. Those can be performed in this step

```bash
# The steps that will be executed in the post push stage
PUST_PUSH=kubernetes
```

# Automated Testing
The project contains automated tests to verify that deployments don't break when new changes are made to deploy-scripts.

**Since deployments work over ssh, running the tests requires you to add your own SSH public key to the $HOME/.ssh/authorized_keys file in your home directory.**

```bash
cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
```

Currently, deployments for the following project types can be tested

```bash
# Test Java (Spring Boot) deployment
sh tests/java.sh
# Test Ruby on Rails deployment
sh tests/rails.sh
# Test React JS deployment
sh tests/reactjs.sh
# Test Next JS deployment
sh tests/nextjs.sh
# Test Django deployment
sh tests/django.sh
# Test Static HTML and PHP website deployment
sh tests/php.sh
# Test actix-web deployment
sh tests/actix.sh
# Test Node JS deployment
sh tests/node.sh
# Test deployment with dockerization on remote host (dockerizes sample Django project)
sh tests/docker.sh
# Test deployment with push to docker registry and pull from registry to a remote host
sh tests/docker-pull.sh
```

# Licence

The code is distributed under the MIT License, a copy of which is included in the project repository.

# Customizing build steps

The steps that are run during a deployment are set by the STEPS variable. Its is a shell variable with a space separated list of step names, whose default value is `STEPS="repo build format package push post_push"`. A normal deployment proceeds along these steps, provided the proper configuration variables are set correctly.

### Adding an additional step

Additional step(s) can be added to a deployment by defining shell variables with the `BEFORE_` or `AFTER_` prefixes in front of existing build step names to insert a step into the list of existing steps.

For example, to add a custom step called `test` before build, you can add a variable `BEFORE_build="test"` to `config.sh` or `app-config.sh`.

```bash
BEFORE_build="test"
```

And define the logic to be executed during this step inside a `ds_exec_step()` function inside either the `deploy/scripts/steps/test.sh` file (for project wide step) or inside `deploy/environments/[environment name]/scripts/steps/test.sh` (for environment specific step). The environment specific logic, if present, will override the project-wide one.

All the variables defined inside `app-config.sh` and `config.sh` are available in this function.

```bash
# deploy/scripts/steps/test.sh

ds_exec_step() {
	title 'test step'
	printf "Running tests for $SERVICE_NAME ... "
}
```

Complex builds and deployments can be configured containing dependencies from other projects, conditional logic while preparing the deployment, etc. with custom steps.

# Configuration Variables

Simple deployment configuration is controlled almost entirely through shell variables, which can be defined in the project-wide app-config.sh or the environment-specific config.sh. Environment-specific variables override project wide variables.

Here is a list of variables that are configurable

### `TYPE`

Project type.

Currently allowed values:

- `java`

- `rails`

- `python`

- `node`

- `reactjs`

- `nextjs`

- `rust` - currently only tested with actix-web

- `html` - for static HTML sites or simple PHP sites

### `BUILD`

Build type depending on the project type variable.

Currently allowed values:

- `mvnw` - for java projects

- `cargo` - for rust projects

- `npm` - for reactjs and nextjs projects

### `FORMAT`

The format that files should be arranged in for deployment.

Currently allowed values:

- `spring-boot` - for java projects

- `rails` - for rails projects

- `node` - for node projects

- `django` - for python projects

- `reactjs` - for reactjs projects

- `nextjs` - for nextjs projects

- `actix-web` - for actix-web projects

- `static` - for static HTML sites or simple PHP sites

### `FORMAT_INCLUDE`

An optional space-separated list of files and directories relative to the project root to be copied over to the deployment files being readied for packaging

### `REPO`

The git repo from which to clone the project.

### `GIT_BRANCH`

The branch which should be used for the deployment. If left unset, it will use the local git branch for deployment

### `PACKAGE`

The format in which to package the deployment files.

Currently allowed values:

- `git` - default value. The default method is to create a bare git repo on the deployment server and push the deployment files to it and use a post-receive git hook to set up and start the deployed project. The files are packaged as a git repo which is then pushed to the bare repo

- `docker` - to package the files into a docker image. Requires a Dockerfile and a docker-compose.yml file to be supplied

- `zip` - uses the zip program to archive the files to be packaged into a .zip archive

### `PUSH`

The method to deliver the deployment to the destination.

Currently allowed values:

- `git-bare` default value. By default the deployment files are pushed to a bare git repo on the deployment server and a post-recieve hook is used to set up and start the project

- `docker` - to push the docker image built when `PACKAGE=docker` to a docker registry

- `s3` - to push to AWS S3. Currently only works with `PACKAGE=zip`. See [S3_BUCKET_PATH](#s3_bucket_path) variable on how to set the target S3 bucket.

### `POST_PUSH`

The step to execute after the deployment files are pushed to the destination.

- `docker-pull` - Uses the docker-compose.yml file supplied to pull the image and start the container on a remote host

- `kubernetes` - creates (or updates) a kubernetes service and deployment with the built docker image

- `ecs` - restarts an existing Amazon ECS task

### `SERVICE_NAME`

The name to identify the service being deployed. For example `my-project`.

### `PROJECT_ENVIRONMENT`

Deduced from the name of the directory under `environments/`. No need to explicitly set.

### `LINKED_DIRS`

Space-separated list of persistent directories to symlink the deployment to. Usually used when sharing persistent directories between deployments.

### `LINKED_FILES`

Space-separated list of persistent files to symlink the deployment to. Usually used when sharing persistent files, like configuration or login/access credential files between deployments.

### `DEPLOYMENT_SERVER`

The hostname or IP address of the server to deploy to.

### `DEPLOYMENT_SERVER_USER`

The SSH user to use to connect to the `DEPLOYMENT_SERVER` for transferring the deployment files. Default value is `deploy`

### `DEPLOYMENT_SERVER_PORT`

The SSH port on the remote server to deploy to. Default value is `22`.

### `DEPLOYMENT_DIR`

The directory on the remote server to which the project must be deployed. The default value is `$HOME/sites/$SERVICE_NAME/$PROJECT_ENVIRONMENT`.

### `DS_DIR`

The directory under the project directory where deploy-scripts files are maintained. The default value is `deploy/`. For rails projects, the default value is `config/deploy-scripts`.

### `DS_UPDATE`

Update deploy-scripts before deploying project. Default value is `true`.

### `REPO_TYPE`

The type of repo to fetch the code from. Default and only currently supported value is `git`.

### `RESTART_COMMAND`

The shell command to execute to start the deployed service. Default value is `sh deploy/run.sh restart`, which uses the bundled run.sh script which can start/stop spring-boot, rails, and django projects.

### `RELEASE_COUNT`

The no of previous releases to keep on the remote server.

## Docker Variables

### `DOCKERIZE`

When set to `true`, it will use the supplied Dockerfile and docker-compose.yml on the remote server to build an image from the deployed files and start a container with it.
**This is different from when the PACKAGE variable is set to docker, which will build the image on your local system before pushing it to a registry**

### `DOCKER_REGISTRY`

When `PUSH=docker`, the target docker registry it should push to is specified by the DOCKER_REGISTRY variable.

### `DOCKER_HOME`

When `PUSH=docker`, the directory containing the config.json from which the docker registry login credentials are read.

### `DOCKER_DELETE_LOCAL_IMAGE`

Default value is `false`. When set to true, the built image will be deleted from the local system after it is pushed to the docker registry. **To use cached docker layers for faster image builds, keep this variable set to false**.

## Kubernetes Variables

### `KUBERNETES_CRED`

When `POST_PUSH=kubernetes`, the kubernetes secret that contains the credentials to pull docker images from a private registry. If your `DOCKER_REGISTRY` is private and needs a username and password to access, you must create a kubernetes secret with the credentials and set this variable.

### `KUBERNETES_HOME`

When `POST_PUSH=kubernetes`, the directory containing the kubernetes cluster configuration yaml files needed to connect to and manage the cluster you are deploying to. Default value is `$HOME/.kube`.

### `KUBERNETES_CLUSTER`

When `POST_PUSH=kubernetes`, the identifier for the kubernetes cluster you are deploying to. deploy-scripts will search for a yaml file named with this identifier to use to connect to the cluster. For example, if is variable is set to `my-cluster`, it will look for a `my-cluster.yaml` in the `KUBERNETES_HOME` directory for the cluster configuration.

### `KUBERNETES_CLUSTER_CONFIG`

When `POST_PUSH=kubernetes`, you can explicitly specify the path of the cluster yaml file. If unspecified it will try to locate the yaml file at `$KUBERNETES_HOME/$KUBERNETES_CLUSTER.yaml`.

### `KUBERNETES_NAMESPACE`

The kubernetes namespace under which the service should be deployed. If unspecified, the service is deployed under the `default` kubernetes namespace.

### `KUBERNETES_INGRESS`

When `POST_PUSH=kubernetes`, the nginx ingress service being used as a load balancer for your kubernetes services. Currently only HTTP(s) load balancing is set up.

### `KUBERNETES_NGINX_SERVICE_HOST`

When `POST_PUSH=kubernetes`, this can be used to explicitly specify the hostname to use for the service. If unspecified, it will try to use `SERVICE_NAME` as the hostname for the service.

### `KUBERNETES_NGINX_SERVICE_PORT`

The service port to use for the deployed kubernetes service. Default value is `80`.

### `KUBERNETES_CERT_MANAGER`

When `POST_PUSH=kubernetes`, the certificate manager that has been configured for certificate issue and renewal on your kubernetes cluster, if you want to enable HTTPS for your deployment.

### `KUBERNETES_TLS`

When `POST_PUSH=kubernetes`, whether to enable HTTPS for your deployment. Default value is `false`. If set to true, you must also set the `KUBERNETES_CERT_MANAGER` variable.

### `KUBERNETES_REPLICAS`

When `POST_PUSH=kubernetes`, the number of replicas to enable for your kubernetes service. Default value is `1`.

## AWS Variables

### `ECS_CLUSTER`

When `POST_PUSH=ecs`, the name of your Amazon ECS cluster where your task is running.

### `ECS_SERVICE`

When `POST_PUSH=ecs`, the name of your Amazon ECS task that you need to restart after the deployment.

### `ECS_STOP_RUNNING_TASKS`

When `POST_PUSH=ecs`, whether to kill the currently running task before starting a new one. Default value is `false`

### `AWS_PROFILE`

The value to use for the --profile argument for aws cli. The default value is `default`

### `S3_BUCKET_PATH`

When `PACKAGE=zip`, the resulting zip file can be pushed to an S3 bucket, if the proper set of credentials for aws cli are configured in your home directory. A sample path would look like `S3_BUCKET_PATH="my-bucket/prefix1/prefix2/etc"`. The path shouldn't contain the `s3://` protocol string.
