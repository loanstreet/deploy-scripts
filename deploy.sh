#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))
mkdir -p $SCRIPT_PATH/scripts
cd $SCRIPT_PATH/scripts
git init
git config core.sparsecheckout true
echo 'scripts' > .git/info/sparse-checkout
git remote add -f origin git@git.loanstreet.com.my:loanstreet/deploy-scripts.git
git pull origin master

sh deploy.sh $1
