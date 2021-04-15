# deploy-scripts

1. [Overview](#overview)
2. [Sample Deployment](#sample-deployment)
3. [Deployment Steps](#deployment-steps)
4. [Adding deployment to a project](#adding-deployment-to-a-project)
5. [Automated Testing](#automated-testing)
6. [Licence](#licence)
7. [Configuration Variables](#configuration-variables)

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
```

The project is still under heavy development and is being updated to include support for other tools.

As much as possible, any new code added to this project should be able to run in a POSIX shell. Exceptions can be made depending on the project you are deploying (eg. bash is ok to use with rails specific parts because a lot of rails related tools need bash anyway).

The following stacks are currently supported

- Java lib projects and Spring Boot (with Maven Wrapper used for building the jar file)
- Ruby on Rails
- Django
- React JS
- Node JS

Support has also been added to containerize and deploy projects built on the above stacks with:

- Docker
- Kubernetes
- Amazon ECS

Containerization has currently only been tested and confirmed to work with Django, Ruby on Rails, Java and React JS projects, but it shouldn't be difficult to add it to the other supported stacks.

- Once added to a project, it copies over the following files:

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

## Sample Deployment

For a step-by-step understanding of how a deployment happens, and how to add deployment support to a project, please check the [Sample Django Deployment](https://github.com/loanstreet/deploy-scripts/wiki/Sample-Django-Deployment) wiki page.

## Deployment Steps

All projects must have the following vars defined (in app-config.sh or config.sh) so that the relevant steps are executed.

```bash
# The project type. Currently supported options are: java, rails, python, node, and reactjs
TYPE=rails
# The name that will be used to label the app that is being deployed, commonly the hostname where the service is made available is used
SERVICE_NAME=service.com
```
A typical deployment then proceeds in a number of steps, as follows. Some steps are optional. The expectation is that each of these steps should support several options which can be combined for different types of deployments.

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

# Adding deployment to a project

To add deployment capabilities to a project, run the following commands

```bash
git clone --single-branch --branch 0.6.0 --depth=1 git@github.com:loanstreet/deploy-scripts.git $HOME/.deploy-scripts/0.6.0

cd $HOME/.deploy-scripts/0.6.0/installer

# For a Java Maven (mvnw) Project
sh install.sh java /path/to/java/project

# or for a Rails project
sh install.sh rails /path/to/rails/project

# or for a Django project
sh install.sh python /path/to/django/project

# or for a reactjs project
sh install.sh reactjs /path/to/reactjs/project

# or for a node project
sh install.sh node /path/to/node/project
```

Follow the instructions given by the installer

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
# Test Django deployment
sh tests/django.sh
# Test Node JS deployment
sh tests/node.sh
# Test deployment with dockerization on remote host (dockerizes sample Django project)
sh tests/docker.sh
# Test deployment with push to docker registry and pull from registry to a remote host
sh tests/docker-pull.sh
```

# Licence

The code is distributed under the MIT License, a copy of which is included in the project repository.

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

### `BUILD`

Build type depending on the project type variable.

Currently allowed values:

- `mvnw` - for java projects

- `npm` - for reactjs projects

### `FORMAT`

The format that files should be arranged in for deployment.

Currently allowed values:

- `spring-boot` - for java projects

- `rails` - for rails projects

- `node` - for node projects

- `django` - for python projects

- `reactjs` - for reactjs projects

### `REPO`

The git repo from which to clone the project.

### `GIT_BRANCH`

The branch which should be used for the deployment. If left unset, it will use the local git branch for deployment

### `PACKAGE`

The format in which to package the deployment files.

Currently allowed values:

- `git` - default value. The default method is to create a bare git repo on the deployment server and push the deployment files to it and use a post-receive git hook to set up and start the deployed project. The files are packaged as a git repo which is then pushed to the bare repo

- `docker` - to package the files into a docker image. Requires a Dockerfile and a docker-compose.yml file to be supplied

### `PUSH`

The method to deliver the deployment to the destination.

Currently allowed values:

- `git-bare` default value. By default the deployment files are pushed to a bare git repo on the deployment server and a post-recieve hook is used to set up and start the project

- `docker` - to push the docker image built when `PACKAGE=docker` to a docker registry

### `POST_PUSH`

The step to execute after the deployment files are pushed to the destination.

- `docker-pull` - Uses the docker-compose.yml file supplied to pull the image and start the container on a remote host

- `kubernetes` - creates (or updates) a kubernetes service and deployment with the built docker image

- `ecs` - restarts an existing Amazon ECS task

### `SERVICE_NAME`

The name to identify the service being deployed. For example `my-project`.

### `PROJECT_ENVIRONMENT`

Deduced from the name of the directory under `environments/`.

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

### `DOCKERIZE`

When set to `true`, it will use the supplied Dockerfile and docker-compose.yml on the remote server to build an image from the deployed files and start a container with it.
**This is different from when the PACKAGE variable is set to docker, which will build the image on your local system before pushing it to a registry**

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

### `DOCKER_REGISTRY`

When `PUSH=docker`, the target docker registry it should push to is specified by the DOCKER_REGISTRY variable.

### `DOCKER_DELETE_LOCAL_IMAGE`

Default value is `false`. When set to true, the built image will be deleted from the local system after it is pushed to the docker registry. **To use cached docker layers for faster image builds, keep this variable set to false**.

### `KUBERNETES_CRED`

When `PUSH=kubernetes`, the kubernetes secret that contains the credentials to pull docker images from a private registry. If your `DOCKER_REGISTRY` is private and needs a username and password to access, you must create a kubernetes secret with the credentials and set this variable.

### `KUBERNETES_HOME`

When `PUSH=kubernetes`, the directory containing the kubernetes cluster configuration yaml files needed to connect to and manage the cluster you are deploying to. Default value is `$HOME/.kube`.

### `KUBERNETS_CLUSTER`

When `PUSH=kubernetes`, the identifier for the kubernetes cluster you are deploying to. deploy-scripts will search for a yaml file named with this identifier to use to connect to the cluster. For example, if is variable is set to `my-cluster`, it will look for a `my-cluster.yaml` in the `KUBERNETES_HOME` directory for the cluster configuration.

### `KUBERNETES_CLUSTER_CONFIG`

When `PUSH=kubernetes`, you can explicitly specify the path of the cluster yaml file. If unspecified it will try to locate the yaml file at `$KUBERNETES_HOME/$KUBERNETES_CLUSTER.yaml`.

### `KUBERNETES_NAMESPACE`

The kubernetes namespace under which the service should be deployed. If unspecified, the service is deployed under the `default` kubernetes namespace.

### `KUBERNETES_INGRESS`

When `PUSH=kubernetes`, the nginx ingress service being used as a load balancer for your kubernetes services. Currently only HTTP(s) load balancing is set up.

### `KUBERNETES_NGINX_SERVICE_HOST`

When `PUSH=kubernetes`, this can be used to explicitly specify the hostname to use for the service. If unspecified, it will try to use `SERVICE_NAME` as the hostname for the service.

### `KUBERNETES_NGINX_SERVICE_PORT`

The service port to use for the deployed kubernetes service. Default value is `80`.

### `KUBERNETES_CERT_MANAGER`

When `PUSH=kubernetes`, the certificate manager that has been configured for certificate issue and renewal on your kubernetes cluster, if you want to enable HTTPS for your deployment.

### `KUBERNETES_TLS`

When `PUSH=kubernetes`, whether to enable HTTPS for your deployment. Default value is `false`. If set to true, you must also set the `KUBERNETES_CERT_MANAGER` variable.

### `KUBERNETES_REPLICAS`

When `PUSH=kubernetes`, the number of replicas to enable for your kubernetes service. Default value is `1`.

### `ECS_CLUSTER`

When `PUSH=ecs`, the name of your Amazon ECS cluster where your task is running.

### `ECS_SERVICE`

When `PUSH=ecs`, the name of your Amazon ECS task that you need to restart after the deployment.

### `ECS_STOP_RUNNING_TASKS`

When `PUSH=ecs`, whether to kill the currently running task before starting a new one. Default value is `false`
