#!/bin/sh

git checkout master
git push origin master
git push origin develop
git push --tags

git pull origin master
git fetch --tags

git submodule init
git submodule update
