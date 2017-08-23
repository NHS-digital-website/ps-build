# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# include some helpers
rootDir = File.expand_path('.')
require "#{rootDir}/vagrant/shame.rb"
require "#{rootDir}/vagrant/config.rb"
require "#{rootDir}/vagrant/plugins.rb"

vm_name = ENV['ROLE']
cfg_dir = "#{rootDir}/ansible/roles/service/#{vm_name}"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |m_config|

	cfg = getConfig("#{rootDir}/vagrant")

	m_config.vm.define vm_name do |config|
		# TODO: change me
		config.vm.box = "ubuntu/xenial64"
		config.vm.box_check_update = true

		config.ssh.forward_agent = true

		config.vm.network :private_network,
		ip: cfg[vm_name]['vm']['priv_ip']

		config.vm.provision :hostsupdate, run: 'always' do |host|
			host.hostname = vm_name
			host.manage_guest = true
			host.manage_host = true
			host.aliases = cfg[vm_name]['vm']['hosts']
		end

		config.vm.provider :virtualbox do |vb|
			vb.customize ["modifyvm", :id, "--memory", cfg[vm_name]['vm']['memory']]
			vb.customize ["modifyvm", :id, "--cpus", cfg[vm_name]['vm']['cores']]
			vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
			vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
		end

		config.vm.provision "shell" do |shell|
			shell.inline = "apt-get update \
			&& apt-get install python2.7 -y \
			&& ln -fs /usr/bin/python2.7 /usr/bin/python"
		end

		build_steps = getBuildSteps(ENV['MODE'])
		build_steps.each do | run |
			config.vm.provision "ansible" do |ansible|
				ansible.playbook = "#{rootDir}/ansible/roles/service/#{vm_name}/#{run['play']}.yml"
				ansible.extra_vars = {
					'hosts' => vm_name,
					'pwd' => rootDir,
					'root_dir' => "#{rootDir}/ansible"
				}.merge(cfg)
				ansible.tags = run['tags']
				ansible.verbose = "#{ENV['VERBOSE']}" if ENV['VERBOSE']
			end
		end
	end
end
