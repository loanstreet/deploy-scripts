# Overview

deploy-scripts is a collection of shell scripts to automate the packaging and deployment of projects.
It is still under heavy development and is being updated to include support for other tools.

As much as possible, any new code added to this project should be able to run on a POSIX shell. Exceptions can be made depending on the project you are deploying (eg. bash is ok to use with rails specific parts because a lot of rails related tools need bash anyway).

The following stacks are currently supported

- Java lib projects and Spring Boot (with Maven Wrapper used for building the jar file)
- Ruby on Rails
- Django
- React JS

Support has also been added to containerize and deploy projects built on the above stacks with:

- Docker
- Kubernetes

The basic way it works is as follows.

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

## Deployment Steps

All projects must have the following vars defined (in app-config.sh or config.sh) so that the relevant steps are executed.

```bash
# The project type. Currently supported options are: java, rails, python, and reactjs
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

Optional. Sometimes (currently only in the case of kubernetes), you need to perform some actions to update the deployment with the new version from the machine you are deploying from. Those can be performed in this step

```bash
# The steps that will be executed in the post push stage
PUST_PUSH=kubernetes
```

# Adding deployment to a project

To add deployment capabilities to a project, run the following commands

```bash
git clone --single-branch --branch 0.5.0 --depth=1 git@git.loansreet.com.my:loanstreet/deploy-scripts.git $HOME/.deploy-scripts

cd $HOME/.deploy-scripts/0.5.0/installer

# For a Java Maven (mvnw) Project
sh install.sh java /path/to/java/project

# or for a Rails project
sh install.sh rails /path/to/rails/project

# or for a Django project
sh install.sh python /path/to/django/project

# or for a reactjs project
sh install.sh reactjs /path/to/reactjs/project
```

Follow the instructions given by the installer

# Automated Testing
The project contains automated testing to verify that deployments don't break when new changes are made to deploy-scripts.

**Since deployments work over ssh, running the tests requires you to add your own SSH public key to the $HOME/.ssh/authorized_keys file in your home directory.**

```bash
cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
```

Currently, deployments for the following project types can be tested

```bash
# Java
sh tests/java.sh
# Ruby on Rails
sh tests/rails.sh
# React JS
sh tests/reactjs.sh
# Django
sh tests/django.sh
# Docker
sh tests/docker.sh
# Kubernetes
sh tests/kubernetes.sh
```
