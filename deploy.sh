#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
mkdir -p $SCRIPT_PATH/deploy-scripts
cd $SCRIPT_PATH/deploy-scripts
git init
git config core.sparsecheckout true
echo 'deploy.sh' > .git/info/sparse-checkout
echo 'scripts' > .git/info/sparse-checkout
git remote add -f origin git@git.loanstreet.com.my:loanstreet/deploy-scripts.git
git pull origin master
git --work-tree=../ --git-dir=.git checkout -f
cd $SCRIPT_PATH
rm -rf $SCRIPT_PATH/deploy-scripts

sh scripts/deploy.sh $1
