#!/bin/sh

# create the basic directory structure required by Wunder::Framework

mkdir conf
mkdir conf/dev
mkdir conf/live
mkdir conf/staging
touch conf/dev/apache.conf
touch conf/live/apache.conf
touch conf/staging/apache.conf
touch conf/dev/base.cfg
touch conf/staging/base.cfg
touch conf/live/base.cfg
touch conf/dev/log4perl.conf
touch conf/staging/log4perl.conf
touch conf/live/log4perl.conf
mkdir cron
mkdir db
mkdir db/backup
mkdir db/changes
mkdir db/schema
mkdir db/backup/mysql_schema
mkdir db/backup/pre_upgrade
mkdir lib
mkdir lib/Wunder
mkdir logs
touch logs/perl.log
chmod 777 perl.log
mkdir t
mkdir templates
mkdir tools
mkdir tools/single_use
mkdir web
