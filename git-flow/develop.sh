#!/bin/sh

git checkout develop 
git pull origin develop
git pull origin master

git push origin develop
git push --tags
git fetch --tags

git submodule init
git submodule update
