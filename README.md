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

# Automated Testing
The project now contains automated testing to verify that deployments don't break when new changes are introduced to the scripts.
Currently, the following project-types are tested for deployment on every merge into homedir_install branch

- Ruby on Rails
To run the test for a ruby on rails deployment, please run
```
sh tests/rails.sh
```
in the root of deploy-scripts