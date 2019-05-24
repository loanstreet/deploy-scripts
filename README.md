# Adding deployment to a project

To add deployment capabilities to a project, run the following commands
```
git clone --single-branch --branch homedir_install --depth=1 $HOME/.deploy-scripts

cd $HOME/.deploy-scripts/installer

# For a Java Maven (mvnw) Project
sh install.sh java /path/to/java/project

# or for a Rails project
sh install.sh rails /path/to/rails/project
```
Follow the instructions from the installer

# Supported project types
Currently, the following project types are supported
- Java Maven Wrapper builds
- Rails (with puma)