Vagrant.configure(2) do |config|
  config.vm.box = 'hashicorp/precise64'

  (1..2).each do |i|
    name = "ansible-test-worker-#{i}"

    config.vm.define name do |machine|
      machine.vm.provider :docker do |d|
        d.image = 'baxterstockman/minideb-vagrant'
        d.has_ssh = true
      end

      machine.ansible.groups = {
        'worker' => name,
        'cluster:children' => ['worker']
      }
    end
  end

  config.vm.define 'ansible-test-control' do |machine|
    machine.vm.provider :docker do |d|
      d.image = 'baxterstockman/minideb-vagrant'
      d.has_ssh = true
    end

    machine.vm.provision :ansible_auto do |ansible|
      ansible.limit = '*'
      ansible.playbook = 'playbooks/test.yml'
    end

    machine.ansible.groups = {
      'control' => ['ansible-test-control'],
      'cluster:children' => ['control']
    }
  end

  config.ansible.vars = {
    'control' => {
      'role'  => 'ansible-control'
    },
    'worker' => {
      'role'  => 'ansible-worker'
    }
  }
end
