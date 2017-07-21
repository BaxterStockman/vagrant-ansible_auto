# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/host'

describe VagrantPlugins::AnsibleAuto::Host do
  include_context 'host'

  let(:hostvars) do
    {
      ansible_ssh_user: 'me',
      ansible_ssh_host: 'foo.bar.net',
      ansible_ssh_port: 2222,
      ansible_ssh_private_key_file: '/path/to/private_key'
    }
  end

  describe '#name' do
    it 'corresponds to the first parameter of the constructor' do
      expect(host.name).to eq machine_name
    end
  end

  describe '#inventory_hostname' do
    it 'corresponds to the first parameter of the constructor, stringified' do
      expect(host.inventory_hostname).to eq machine_name.to_s
    end
  end

  describe '#ssh_user' do
    it 'corresponds to hostvars[:ansible_ssh_user]' do
      expect(host.ansible_ssh_user).to eq 'me'
    end
  end

  describe '#ssh_host' do
    it 'corresponds to hostvars[:ansible_ssh_host]' do
      expect(host.ansible_ssh_host).to eq 'foo.bar.net'
    end
  end

  describe '#ssh_port' do
    it 'corresponds to hostvars[:ansible_ssh_port]' do
      expect(host.ansible_ssh_port).to eq 2222
    end
  end

  describe '#ssh_private_key_file' do
    it 'corresponds to hostvars[:ansible_ssh_private_key_file]' do
      expect(host.ansible_ssh_private_key_file).to eq '/path/to/private_key'
    end
  end

  describe '#hostvars' do
    it 'stringifies its keys' do
      expect(host.hostvars).to eq(
        'ansible_ssh_user'              => 'me',
        'ansible_ssh_host'              => 'foo.bar.net',
        'ansible_ssh_port'              => 2222,
        'ansible_ssh_private_key_file'  => '/path/to/private_key'
      )
    end
  end

  describe '#to_h' do
    it 'returns #hostvars keyed to #inventory_hostname' do
      expect(host.to_h).to eq(host.inventory_hostname => {
                                'ansible_ssh_user'              => 'me',
                                'ansible_ssh_host'              => 'foo.bar.net',
                                'ansible_ssh_port'              => 2222,
                                'ansible_ssh_private_key_file'  => '/path/to/private_key'
                              })
    end
  end

  describe "a method starting with `ansible_'" do
    it 'dispatches to hostvars' do
      host.ansible_python_interpreter = '/usr/bin/python2.7'
      expect(host.ansible_python_interpreter).to eq '/usr/bin/python2.7'
      expect(host.hostvars[:ansible_python_interpreter]).to eq '/usr/bin/python2.7'
    end
  end

  describe '#to_ini' do
    it 'returns #to_h as INI-style lines' do
      expect(host.to_ini).to eq(unindent(<<-HOST).chomp)
        #{inventory_hostname} ansible_ssh_host=foo.bar.net ansible_ssh_port=2222 ansible_ssh_private_key_file=/path/to/private_key ansible_ssh_user=me
      HOST
    end
  end
end

describe VagrantPlugins::AnsibleAuto::HostMachine do
  include_context 'host'

  describe '#ansible_ssh_user' do
    it 'corresponds to machine.ssh_info[:username]' do
      expect(ssh_info).to receive(:[]).with(:username).and_return('me')
      expect(host_machine.ansible_ssh_user).to eq 'me'
    end
  end

  describe '#ansible_ssh_host' do
    it 'corresponds to machine.ssh_info[:host]' do
      expect(ssh_info).to receive(:[]).with(:host).and_return('foo.bar.net')
      expect(host_machine.ansible_ssh_host).to eq 'foo.bar.net'
    end
  end

  describe '#ansible_ssh_port' do
    it 'corresponds to machine.ssh_info[:port]' do
      expect(ssh_info).to receive(:[]).with(:port).and_return(2222)
      expect(host_machine.ansible_ssh_port).to eq 2222
    end
  end

  describe '#ansible_ssh_private_key_file' do
    it 'corresponds to machine.ssh_info[:private_key_path]' do
      expect(machine.config.ssh).to receive(:insert_key).and_return(true)
      expect(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return(['/path/to/private_key'])
      expect(host_machine.ansible_ssh_private_key_file).to eq '/path/to/private_key'
    end

    it 'has no default' do
      expect(machine.config.ssh).to receive(:insert_key).and_return(true)
      expect(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return([])
      expect(host_machine.ansible_ssh_private_key_file).to be_nil
    end
  end
end
