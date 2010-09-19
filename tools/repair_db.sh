#!/bin/sh

mysqlcheck -u root -p --auto-repair --check --optimize $1
