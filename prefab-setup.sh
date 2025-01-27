#!/usr/bin/env bash

##
# Prefab
# Install and setup script for Prefab
##

echo "Installing Prefab"

if ! type node > /dev/null 2>&1 && ! which node > /dev/null 2>&1
then
    echo "Please install Node.js - see: https://nodejs.org/en/download"
fi;

if ! type npm > /dev/null 2>&1 && ! which npm > /dev/null 2>&1
then
    echo "Please install NPM - see: https://docs.npmjs.com/downloading-and-installing-node-js-and-npm"
fi;

npm i -g git+ssh://github.com:bigbite/prefab

# Check command exists and has installed
if ! command -v prefab 2>&1 >/dev/null
then
    echo "prefab command could not be found"
    exit 1
fi

echo "Registering Theme template"
prefab register theme git@github.com:bigbite/prefab-theme-template.git

echo "Registering Plugin template"
prefab register plugin git@github.com:bigbite/prefab-plugin-template.git

echo "Registering WordPress Project template"
prefab register wp-project git@github.com:bigbite/prefab-wp-project-template.git

echo "Prefab installation complete - read more at https://github.com/bigbite/prefab"