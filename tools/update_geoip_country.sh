#!/bin/sh

mkdir /usr/local/share/GeoIP
cd /usr/local/share/GeoIP
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip GeoIP.dat.gz
