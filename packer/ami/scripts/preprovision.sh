#!/bin/bash
set -euo pipefail

function main {
	sudo rm -f /etc/cron.daily/apt-compat

	while [ ! -f /var/lib/cloud/instance/boot-finished ];
		do echo 'Waiting for cloud-init...';
		sleep 1;
	done

	sudo systemctl stop apt-daily.timer
	sudo systemctl disable apt-daily.timer
	sudo systemctl mask apt-daily.service
	sudo systemctl daemon-reload

	# Need to ensure python is installed so Ansible can run
	sudo apt-get update

	# In case some cron task kicks in befor our script...
	while sudo lsof /var/lib/dpkg/lock; do
		echo 'Waiting for dpkg lock to be removed...';
		sudo ps aux | grep apt;
		sudo ps aux | grep dpkg;
		sudo ps aux | grep aptitude;
		sudo lsof /var/lib/dpkg/lock || echo "no lock"
		sleep 3;
	done

	sudo apt-get install -y python2.7
	sudo ln -fs /usr/bin/python2.7 /usr/bin/python
}

main "$@"
