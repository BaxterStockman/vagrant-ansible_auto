# Vagrant::AnsibleAuto

[![Build Status](https://secure.travis-ci.org/BaxterStockman/vagrant-ansible_auto.png?branch=master)](https://travis-ci.org/BaxterStockman/vagrant-ansible_auto)
[![Dependency Status](https://gemnasium.com/BaxterStockman/vagrant-ansible_auto.png)](https://gemnasium.com/BaxterStockman/vagrant-ansible_auto)
[![Code Climate](https://codeclimate.com/github/BaxterStockman/vagrant-ansible_auto.png)](https://codeclimate.com/github/BaxterStockman/vagrant-ansible_auto)
[![Coverage Status](https://coveralls.io/repos/github/BaxterStockman/vagrant-ansible_auto/badge.svg?branch=travis)](https://coveralls.io/github/BaxterStockman/vagrant-ansible_auto?branch=travis)
[![Gem Version](https://img.shields.io/gem/v/vagrant-ansible_auto.svg)](https://rubygems.org/gems/vagrant-ansible_auto)

This Vagrant plugin provides the `ansible_auto` provisioner that automatically
sets up the provisioned guest as an Ansible control machine for the nodes
defined in your Vagrantfile.  It also provides the `vagrant ansible` subcommand
that generates an inventory file for use on your Vagrant host machine.

## Installation

Install with:

```shell
$ vagrant plugin install vagrant-ansible_auto
```

## Usage

### Inventory Generation

Say you have a Vagrantfile with the following contents:

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = 'hashicorp/precise64'

  (1..2).each do |i|
    name = "ansible-test-worker-#{i}"
    config.vm.define name do |target|
    end
  end

  config.vm.define 'ansible-test-control' do |machine|
    machine.vm.provision :ansible_auto do |ansible|
      ansible.limit = '*'
      ansible.playbook = 'playbooks/test.yml'
    end
  end

  config.ansible.groups = {
    'control'           => %w(ansible-test-control),
    'worker'            => %w(ansible-test-worker-1 ansible-test-worker-2),
    'cluster:children'  => %w(control worker),
  }
end
```

Running `vagrant ansible inventory` will print this Ansible inventory:

```ini
ansible-test-worker-1 ansible_ssh_user=vagrant ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222 ansible_ssh_private_key_file=/home/user/vagrant/cluster/.vagrant/machines/ansible-test-worker-1/virtualbox/private_key
ansible-test-worker-2 ansible_ssh_user=vagrant ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200 ansible_ssh_private_key_file=/home/user/vagrant/cluster/.vagrant/machines/ansible-test-worker-2/virtualbox/private_key
ansible-test-control ansible_ssh_user=vagrant ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201 ansible_ssh_private_key_file=/home/user/vagrant/cluster/.vagrant/machines/ansible-test-control/virtualbox/private_key
[control]
ansible-test-control
[worker]
ansible-test-worker-1
ansible-test-worker-2
[cluster:children]
control
worker
```

### Provisioning

The `ansible_auto` provisioner is an augmented version of the
[`ansible_local` provisioner included with Vagrant](https://www.vagrantup.com/docs/provisioning/ansible_local.html).
It accepts all options valid for that provisioner, and adds the following
options:

```ruby
Vagrant.configure(2) do |config|
  config.define 'ansible-control' do |machine|
    machine.provision :ansible_auto do |ansible|
      # Will show up in inventory as
      #   [control]
      #   ansible-control
      ansible.groups = {
        'control'   => %(ansible-control)
      }

      # Will show up in inventory as
      #  [dev:children]
      #  control
      ansible.children = {
        'dev'   => %w(control)
      }

      # Will show up in inventory as
      #   [dev:vars]
      #   git_branch = devel
      ansible.vars = {
        'dev' => {
          'git_branch' => 'devel'
        }
      }

      # Enable or disable `StrictHostKeyChecking` SSH option.
      # Disabled by default.
      ansible.strict_host_key_checking = false

      # The number of times to attempt to connect to a managed host from the
      # Ansible control machine.
      ansible.host_connect_tries = 10

      # The number of seconds to delay between connection attempts.
      ansible.host_connect_sleep = 5
    end
  end
end
```

Each guest provisioned with `ansible_auto` will be set up as an Ansible
control machine with the ability to connect to other guests defined in the
`Vagrantfile`.  This is facilitated by uploading the private keys of each guest
to a temporary path on the control machine and assigning this path as the
hostvar `ansible_ssh_private_key_file` to the relevant host in the generated
inventory.

## Contributing

1. Fork it ( https://github.com/BaxterStockman/vagrant-ansible_auto/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[The MIT licence](LICENSE.md)
