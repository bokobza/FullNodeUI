#!/bin/bash

arch=x64
configuration=Release  
os_platform=linux
log_prefix=LINUX-BUILD
build_directory=$(dirname $(dirname "$0"))

# exit if error
set -o errexit

# print out a few variables
echo "current environment variables:"
echo "OS name:" $os_platform
echo "Build directory:" $build_directory
echo "Architecture:" $arch
echo "Configuration:" $configuration

dotnet --info

# Initialize dependencies
echo $log_prefix STARTED restoring dotnet and npm packages
cd $build_directory
git submodule update --init --recursive

cd $build_directory/StratisCore.UI

echo $log_prefix Running npm install
npm install --verbose

echo $log_prefix Running npm install npx
npm install -g npx --verbose

echo $log_prefix FINISHED restoring dotnet and npm packages

# dotnet publish
echo $log_prefix running 'dotnet publish'
cd $build_directory/StratisBitcoinFullNode/src/Stratis.StratisD
dotnet restore
dotnet publish -c $configuration -r $os_platform-$arch -v m -o $build_directory/StratisCore.UI/daemon

echo $log_prefix chmoding the Stratis.StratisD file
chmod +x $build_directory/StratisCore.UI/daemon/Stratis.StratisD

# node Build
cd $build_directory/StratisCore.UI
echo $log_prefix running 'npm run'
npm run build:prod

# node packaging
echo $log_prefix packaging StratisCore.UI 
npx electron-builder build --linux --$arch
echo $log_prefix finished packaging

echo $log_prefix contents of build_directory
cd $build_directory
ls

echo $log_prefix contents of the app-builds folder
cd $build_directory/StratisCore.UI/app-builds/
# replace the spaces in the name with a dot as CI system have trouble handling spaces in names.
for file in *.{tar.gz,deb}; do mv "$file" `echo $file | tr ' ' '.'` 2>/dev/null || : ; done

ls

echo $log_prefix FINISHED build
