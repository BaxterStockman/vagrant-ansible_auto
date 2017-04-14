# frozen_string_literal: true
require 'spec_helper'

require 'vagrant/ansible_auto/inventory'

describe VagrantPlugins::AnsibleAuto::Inventory do
  subject { described_class.new }

  # include_context 'machine'

  describe '#add_group' do
    it 'adds a list of hosts to the group cache' do
      subject.add_group(:mygroup, 'db', 'bastion', 'firewall')
      subject.groups.tap do |groups|
        expect(groups).to have_key("mygroup")
        expect(groups["mygroup"]).to include('db', 'bastion', 'firewall')
      end
    end

    it 'appends new hosts to existing groups' do
      subject.add_group(:mygroup, 'db', 'bastion', 'firewall')
      subject.add_group(:mygroup, 'repo')
      subject.groups.tap do |groups|
        expect(groups).to have_key("mygroup")
        expect(groups["mygroup"]).to include('db', 'bastion', 'firewall', 'repo')
      end
    end
  end

  describe '#add_host' do
    include_context 'host'

    it 'adds a host to the host cache' do
      subject.add_host(host)
      expect(subject.hosts).to include(host)
    end

    it 'does not allow duplicates' do
      2.times { subject.add_host(host) }
      expect(subject.hosts).to have(1).items
    end

    it 'coerces instances of Vagrant::Machine to instances of Host' do
      subject.add_host(machine)
      expect(subject.hosts).to all(be_a(VagrantPlugins::AnsibleAuto::Host))
    end

    it 'coerces names + hostvars to instances of Host' do
      subject.add_host("mymachine", ansible_ssh_host: 'foo.bar.net')
    end
  end

  describe '#groups=' do
    it 'returns a hash of sets' do
      expect(subject.groups).to be_a(Hash)
      expect(subject.groups[:foo]).to be_a(Set)
    end
  end

  describe '#hosts=' do
    it 'returns a set' do
      expect(subject.hosts).to be_a(Set)
    end
  end

  describe '#vars=' do
    it 'returns a hash of hashes' do
      expect(subject.vars).to be_a(Hash)
      expect(subject.vars[:meh]).to be_a(Hash)
    end
  end

  describe '#children=' do
    it 'returns a hash of sets' do
      expect(subject.children).to be_a(Hash)
      expect(subject.children[:quux]).to be_a(Set)
    end
  end
end
