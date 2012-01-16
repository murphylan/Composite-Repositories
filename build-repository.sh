#!/bin/sh -e
# Author Murphy
#
# Release script, mimicks the buildr release or maven release. For tycho.
# Also "deploys" generated p2-repositories.
#
# Clean
# Reads the main version number and delete '-SNAPSHOT' from it.
# Reads the buildNumber and increment it by 1. Pad it with zeros.
# Replace the context qualifier in the pom.xml by this buildNumber
# Build
# Commit and tags the sources (git or svn)
# Replace the forceContextQualifier's value by qualifier
# Commit
# git branch to checkout.

#load the environment constants
# Absolute path to this script.
SCRIPT=$(readlink -f $0)
# Absolute path this script is in.
SCRIPTPATH=`dirname $SCRIPT`
[ -z "$RELEASE_ENV" ] && RELEASE_ENV=$SCRIPTPATH/default_env
[ -f "$RELEASE_ENV" ] && . $RELEASE_ENV


echo "Executing tycho-release.sh in the folder "`pwd`
#make sure we are at the root of the folder where the chckout actually happened.
if [ ! -d ".git" -a ! -d ".svn" ]; then
  echo "FATAL: could not find .git or .svn in the Current Directory `pwd`"
  echo "The script must execute in the folder where the checkout of the sources occurred."
  exit 2;
fi

if [ -z "$MAVEN3_HOME" ]; then
  MAVEN3_HOME=/home/murphy/soft/murphy/apache-maven-3.0.3
fi

if [ -d ".git" -a -z "$GIT_BRANCH" ]; then
  GIT_BRANCH=master
  export GIT_BRANCH
elif [ -z "$SYM_LINK_CURRENT_NAME" -a $GIT_BRANCH != "master" ]; then
  SYM_LINK_CURRENT_NAME="current_$GIT_BRANCH"
fi

#Base folder on the file system where the p2-repositories are deployed.
if [ -z "$BASE_FILE_PATH_P2_REPO" ]; then
  #Assume we are on the release machine logged in as the release user.
  BASE_FILE_PATH_P2_REPO=/home/murphy/p2repo
fi

if [ -z "$SYM_LINK_CURRENT_NAME" ]; then
  SYM_LINK_CURRENT_NAME="current"
fi

if [ -d ".git" ]; then
  git checkout $GIT_BRANCH
  git pull origin $GIT_BRANCH
elif [ -d ".svn" ]; then
  svn up
fi

# Create the local Maven repository.
if [ -z "$LOCAL_REPOSITORY" ]; then
  LOCAL_REPOSITORY="/home/murphy/.m2/repository"
fi

if [ -n "$SUB_DIRECTORY" ]; then
  cd $SUB_DIRECTORY
fi

if [ -z "$ROOT_POM"]; then
  ROOT_POM="pom.xml"
fi

### Compute the build number.
#tags the sources for a release build.
reg="<version>(.*)-SNAPSHOT<\/version>"
line=`awk '{if ($1 ~ /'$reg'/){print $1}}' < $ROOT_POM | head -1`
echo "line" $line
#version=`echo "$line" | awk 'match($0, '<version>(.*)-SNAPSHOT</version>', a) { print a[1] }'`
version=`echo "<version>1.0.0-SNAPSHOT</version>" | awk -F'[>-]' '{print $2}'`
echo "version" $version

reg2="<forceContextQualifier>(.*)<\/forceContextQualifier>"
buildNumberLine=`awk '{if ($1 ~ /'$reg2'/){print $1}}' < $ROOT_POM | head -1`
echo "buildNumberLine" $buildNumberLine

if [ -z "$buildNumberLine" ]; then
  echo "Could not find the build-number to use in $ROOT_POM; The line $reg2 must be defined"
  exit 2;
fi
#currentBuildNumber=`echo "$buildNumberLine" | awk 'match($0, "'$reg2'", a) { print a[1] }'`
currentBuildNumber=`echo "$buildNumberLine" | awk -F'[><]' '{print $3}'`
echo "currentBuildNumber" $currentBuildNumber

  echo "Increment the buildNumber $currentBuildNumber"
  strlength=`expr length $currentBuildNumber`
  #increment the context qualifier
  buildNumber=`expr $currentBuildNumber + 1`
  #pad with zeros so the build number is as many characters long as before
  printf_format="%0"$strlength"d\n"
  buildNumber=`printf "$printf_format" "$buildNumber"`
  completeVersion="$version.$buildNumber"

export completeVersion
export version
export buildNumber
echo "Build Version $completeVersion"

#update the numbers for the release
sed -i "s/<forceContextQualifier>.*<\/forceContextQualifier>/<forceContextQualifier>$buildNumber<\/forceContextQualifier>/" $ROOT_POM

#we write this one in the build file
timestamp_and_id=`date +%Y-%m-%d-%H%M%S`

#### Build now
$MAVEN3_HOME/bin/mvn -f $ROOT_POM clean verify -Dmaven.repo.local=$LOCAL_REPOSITORY 

### Debian packages build



### P2-Repository 'deployment'
# Go into each one of the folders looking for pom.xml files that packaging type is
# 'eclipse-repository'
# Add a file to identify the build and the version. eventually we could even add some html pages here.
# Then move the repository in its 'final' destination. aka the deployment.
current_dir=`pwd`;
current_dir=`readlink -f $current_dir`
reg3="<packaging>eclipse-repository<\/packaging>"
for pom in `find $current_dir -name pom.xml -type f`
do
  #module_dir=`echo "$pom" | awk 'match($0, "(.*)/pom.xml", a) { print a[1] }'`
  module_dir=`echo "$pom" | awk 'match($0, "(.*)/repository/pom.xml") { print substr($0, RSTART, RLENGTH-8)}'`  
  #echo "module_dir $module_dir"
  #Look for the target/repository folder:
  #if [ -d "$module_dir/target/repository" ]; then
  if [ -d "$module_dir" ]; then
    packagingRepo=`awk '{if ($1 ~ /'$reg3'/){print $1}}' < $pom | head -1`
    if [ ! -z "$packagingRepo" ]; then
      # OK we have a repo project.
      # Let's read its group id and artifact id and make that into the base folder
      # Where the p2 repository is deployed
       artifactId=`xpath -q -e "/project/artifactId/text()" $pom`
       groupId=`xpath -q -e "/project/groupId/text()" $pom`
       if [ -z "$groupId" ]; then
         groupId=`xpath -q -e "/project/parent/groupId/text()" $pom`
       fi
       p2repoPath=$BASE_FILE_PATH_P2_REPO/`echo $groupId | tr '.' '/'`/$artifactId
       p2repoPathComplete="$p2repoPath/$completeVersion"
       if  [ -n "$P2_DEPLOYMENT_FOLDER_NAME" ]; then
         echo "Using P2_DEPLOYMENT_FOLDER_NAME=$P2_DEPLOYMENT_FOLDER_NAME for the final name of the folder where the repository is deployed."
#         SKIP_TAG_AND_DEB_DEPLOYMENT_MSG="Cutting the build short as this is an experimental build for a branch: $P2_DEPLOYMENT_FOLDER_NAME was defined"
         p2repoPathComplete="$p2repoPath/$P2_DEPLOYMENT_FOLDER_NAME"
       else
         P2_DEPLOYMENT_FOLDER_NAME=$completeVersion
       fi
       echo "Deploying $groupId:$artifactId:$completeVersion in $p2repoPathComplete"       
       if [ -d $p2repoPathComplete ]; then
         echo "Warn: Removing the existing repository $p2repoPathComplete"
         rm -rf $p2repoPathComplete
       fi
       mkdir -p $p2repoPath
       mv "$module_dir/target/repository" "$module_dir/target/$P2_DEPLOYMENT_FOLDER_NAME"
       mv "$module_dir/target/$P2_DEPLOYMENT_FOLDER_NAME" $p2repoPath
       if [ -h "$p2repoPath/$SYM_LINK_CURRENT_NAME" ]; then
         rm "$p2repoPath/$SYM_LINK_CURRENT_NAME"
       fi
       #Generate the build signature file that will be read by other builds via tycho-resolve-p2repo-versions.rb
       #to identify the actual version of the repo used as a dependency.
       version_built_file=$p2repoPathComplete/version_built.properties
       echo "artifact=$groupId:$artifactId" > $version_built_file
       echo "version=$completeVersion" >> $version_built_file
       echo "built=$timestamp_and_id" >> $version_built_file
       #must make sure we create the symlink in the right folder to have rsync find it later.
       cd $p2repoPath
       ln -s $completeVersion $SYM_LINK_CURRENT_NAME
       cd $current_dir
    fi
  fi
done
