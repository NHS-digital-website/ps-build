#!/bin/bash -eux

# Delete unneeded files.
rm -f /home/vagrant/*.sh
rm -f /home/vagrant/VBoxGuestAdditions_5.0.32.iso

# Download vagrant ssh key
apt-get install -y curl
mkdir -p /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
curl -so /home/vagrant/.ssh/authorized_keys \
    https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Apt cleanup.
apt-get clean
apt autoremove
apt update

# Zero out the rest of the free space using dd, then delete the written file.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
