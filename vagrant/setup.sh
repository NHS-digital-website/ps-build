#!/bin/bash -eux

# Ensure Python 2.7
apt-get update \
	&& apt-get install python2.7 -y \
	&& ln -fs /usr/bin/python2.7 /usr/bin/python

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable \"0\";' >> /etc/apt/apt.conf.d/10periodic
