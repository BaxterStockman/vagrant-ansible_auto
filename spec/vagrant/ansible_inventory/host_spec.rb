require 'spec_helper'

require 'vagrant/ansible_inventory/host'

describe VagrantPlugins::AnsibleInventory::HostMachine do
  subject { described_class.new(machine) }

  include_context 'machine'

  describe '#ssh_user' do
    it 'corresponds to machine.ssh_info[:username]' do
      expect(ssh_info).to receive(:[]).with(:username).and_return('me')
      expect(subject.ssh_user).to eq 'me'
    end
  end

  describe '#ssh_host' do
    it 'corresponds to machine.ssh_info[:host]' do
      expect(ssh_info).to receive(:[]).with(:host).and_return('foo.bar.net')
      expect(subject.ssh_host).to eq 'foo.bar.net'
    end
  end

  describe '#ssh_port' do
    it 'corresponds to machine.ssh_info[:port]' do
      expect(ssh_info).to receive(:[]).with(:port).and_return(2222)
      expect(subject.ssh_port).to eq 2222
    end
  end

  describe '#ssh_private_key_file' do
    it 'corresponds to machine.ssh_info[:private_key_path]' do
      expect(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return(['/path/to/private_key'])
      expect(subject.ssh_private_key_file).to eq '/path/to/private_key'
    end

    it 'has no default' do
      expect(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return([])
      expect(subject.ssh_private_key_file).to be_nil
    end
  end
end
