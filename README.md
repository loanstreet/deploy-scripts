# Adding deployment to a project

To add deployment capabilities to a project, run the following commands
```
git clone --single-branch --branch homedir_install --depth=1 git@git.loansreet.com.my:loanstreet/deploy-scripts.git $HOME/.deploy-scripts

cd $HOME/.deploy-scripts/installer

# For a Java Maven (mvnw) Project
sh install.sh java /path/to/java/project

# or for a Rails project
sh install.sh rails /path/to/rails/project

# or for a reactjs project
sh install.sh reactjs /path/to/reactjs/project
```
Follow the instructions from the installer

# Supported project types
Currently, the following project types are supported
- Java Maven Wrapper builds for Spring boot
- Rails (with puma)
- ReactJS (with npm)
