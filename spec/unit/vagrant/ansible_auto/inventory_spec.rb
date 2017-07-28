# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/errors'
require 'vagrant/ansible_auto/inventory'

describe VagrantPlugins::AnsibleAuto::Inventory do
  include_context 'inventory'

  let(:inventory_hosts) { %w[db bastion firewall] }

  let(:complex_group) do
    {
      hosts: inventory_hosts,
      vars: {
        this: 'n',
        uh: 'that',
        n: 'uh'
      },
      children: %w[staging qa]
    }
  end

  describe '#add_group' do
    it 'adds a list of hosts to the group cache' do
      inventory.add_group(:mygroup, *inventory_hosts)
      inventory.groups.tap do |groups|
        expect(groups).to have_key('mygroup')
        expect(groups['mygroup']).to include(*inventory_hosts)
      end
    end

    it 'appends new hosts to existing groups' do
      inventory.add_group(:mygroup, *inventory_hosts)
      inventory.add_group(:mygroup, 'repo')
      inventory.groups.tap do |groups|
        expect(groups).to have_key('mygroup')
        expect(groups['mygroup']).to include('repo', *inventory_hosts)
      end
    end

    it 'recognizes a hash in the style returned by executable inventories' do
      inventory.add_group(:mygroup, complex_group)

      inventory.groups.tap do |groups|
        expect(groups).to have_key('mygroup')
        expect(groups['mygroup']).to include(*inventory_hosts)
      end

      inventory.vars.tap do |vars|
        expect(vars).to have_key('mygroup')
        expect(vars['mygroup']).to include(this: 'n', uh: 'that', n: 'uh')
      end

      inventory.children.tap do |children|
        expect(children).to have_key('mygroup')
        expect(children['mygroup']).to include('staging', 'qa')
      end
    end

    context 'given an invalid group name' do
      it 'raises an error' do
        expect { inventory.add_group('_') }.to raise_error do |error|
          expect(error).to be_a(VagrantPlugins::AnsibleAuto::InvalidGroupNameError)
          expect(error.message).to match(/_ is not a valid group name/)
        end
      end
    end
  end

  describe '#add_host' do
    include_context 'host'

    it 'adds a host to the host cache' do
      inventory.add_host(host)
      expect(inventory.hosts).to include(host)
    end

    it 'does not allow duplicates' do
      2.times { inventory.add_host(host) }
      expect(inventory.hosts.size).to eq 1
    end

    it 'coerces instances of Vagrant::Machine to instances of Host' do
      inventory.add_host(machine)
      expect(inventory.hosts).to all(be_a(VagrantPlugins::AnsibleAuto::Host))
    end

    it 'coerces names + hostvars to instances of Host' do
      inventory.add_host('mymachine', ssh_host: 'foo.bar.net')
      mymachine = VagrantPlugins::AnsibleAuto::Host.new('mymachine', ssh_host: 'foo.bar.net')
      expect(inventory.hosts).to all(be_a(VagrantPlugins::AnsibleAuto::Host))
      expect(inventory.hosts).to include(mymachine)
    end

    context 'given an object that cannot be converted to a Host or HostMachine' do
      it 'raises an error' do
        expect { inventory.add_host(6) }.to raise_error(
          VagrantPlugins::AnsibleAuto::Errors::InvalidHostTypeError,
          /cannot add object of type \w+ as inventory host/
        )
      end
    end
  end

  describe '#groups=' do
    let(:new_groups) do
      {
        'foo'   => %w[bar baz quux],
        'pink'  => %w[elephants on parade]
      }
    end

    before do
      inventory.groups = new_groups
    end

    it 'assigns the groups to the inventory' do
      expect(inventory.groups['foo']).to include('bar', 'baz', 'quux')
      expect(inventory.groups['pink']).to include('elephants', 'on', 'parade')
    end

    context 'given a :vars group' do
      let(:group_vars) do
        {
          'this'  => 'that',
          'some'  => 'thing'
        }
      end

      let(:new_groups) do
        {
          'foo'       => %w[mee maw],
          'foo:vars'  => group_vars
        }
      end

      it 'assigns the vars to the given group' do
        expect(inventory.vars['foo']).to include(group_vars)
      end
    end

    context 'given a :children group' do
      let(:group_children) do
        %w[baz quux]
      end

      let(:new_groups) do
        {
          'foo'           => %w[d chain],
          'foo:children'  => group_children
        }
      end

      it 'assigns the provided groups as children of the parent group' do
        expect(inventory.children['foo']).to include(*group_children)
      end
    end

    context 'given a colon-separated group name without :vars or :children' do
      let(:new_groups) do
        {
          'bleep'       => %w[ing computer],
          'bleep:bloop' => %w[er reel]
        }
      end

      it 'treats the group heading as a simple group name' do
        expect(inventory.groups).to include('bleep:bloop')
      end
    end

    context 'given a colon-separated group with backslash-escaped :vars or :children' do
      let(:new_groups) do
        {
          'bleep'       => %w[ing computer],
          'bleep\:vars' => %w[ity lacrosse],
          'bleep\:children' => %w[of the corn]
        }
      end

      it 'treats the group heading as a simple group name' do
        expect(inventory.groups).to include('bleep\:vars')
        expect(inventory.groups).to include('bleep\:children')
        expect(inventory.vars[:bleep]).to be_empty
        expect(inventory.children[:bleep]).to be_empty
      end
    end
  end

  describe '#groups' do
    it 'returns a hash of sets' do
      expect(inventory.groups).to be_a(Hash)
      expect(inventory.groups[:foo]).to be_a(Set)
    end
  end

  describe '#hosts=' do
    it 'sets the hosts for the inventory' do
      inventory.hosts = %w[huey dewey louie]
      expect(inventory.hosts.map(&:name)).to eq(%w[huey dewey louie])
    end

    it 'wipes out any existing hosts' do
      inventory.hosts = %w[huey dewey louie]
      expect(inventory.hosts.map(&:name)).to eq(%w[huey dewey louie])
      inventory.hosts = %w[heckle jeckle]
      expect(inventory.hosts.map(&:name)).to eq(%w[heckle jeckle])
    end
  end

  describe '#hosts' do
    it 'returns a set' do
      expect(inventory.hosts).to be_a(Set)
    end
  end

  describe '#vars=' do
    it 'sets the vars for the inventory' do
      inventory.vars = { bah: { hum: 'bug' } }
      expect(inventory.vars).to eq('bah' => { 'hum' => 'bug' })
    end

    it 'wipes out existing vars' do
      inventory.vars = { bah: { hum: 'bug' } }
      expect(inventory.vars).to eq('bah' => { 'hum' => 'bug' })
      inventory.vars = { bah: { ram: 'ewe' } }
      expect(inventory.vars).to eq('bah' => { 'ram' => 'ewe' })
    end
  end

  describe '#vars' do
    it 'returns a hash of hashes' do
      expect(inventory.vars).to be_a(Hash)
      expect(inventory.vars[:meh]).to be_a(Hash)
    end
  end

  describe '#children=' do
    it 'sets the group children for the inventory' do
      inventory.children = { cronus: ['zeus'] }
      expect(inventory.children.keys).to include('cronus')
      expect(inventory.children[:cronus]).to include('zeus')
    end

    it 'wipes out any existing children' do
      inventory.children = { cronus: ['zeus'] }
      expect(inventory.children.keys).to include('cronus')
      expect(inventory.children[:cronus]).to include('zeus')
      inventory.children = { saturn: ['jupiter'] }
      expect(inventory.children.keys).to include('saturn')
      expect(inventory.children.keys).not_to include('cronus')
      expect(inventory.children[:saturn]).to include('jupiter')
      expect(inventory.children[:cronus]).not_to include('zeus')
    end
  end

  describe '#children' do
    it 'returns a hash of sets' do
      expect(inventory.children).to be_a(Hash)
      expect(inventory.children[:quux]).to be_a(Set)
    end
  end

  describe 'merge' do
    let(:inventory2) { inventory.clone }

    it 'returns a new inventory with hosts, groups, vars, and children merged' do
      inventory.hosts = %w[huey dewey louie]
      inventory.groups = { ducks: %w[huey dewey louie] }
      inventory.children = { birds: %w[ducks] }
      inventory.vars = { birds: { of: 'a feather' }, ducks: { out: 'quick' } }

      inventory2.hosts = %w[heckle jeckle launchpad]
      inventory2.groups = { crows: %w[heckle jeckle], ducks: %w[launchpad] }
      inventory2.children = { birds: %w[crows] }
      inventory2.vars = { birds: { on: 'the wing' }, crows: { with: 'delight' } }

      inventory3 = inventory.merge(inventory2)
      expect(inventory3.hosts.map(&:name)).to include('huey', 'dewey', 'louie', 'launchpad', 'heckle', 'jeckle')
      expect(inventory3.vars).to eq('birds' => { 'on' => 'the wing', 'of' => 'a feather' }, 'ducks' => { 'out' => 'quick' }, 'crows' => { 'with' => 'delight' })
      expect(inventory3.groups.keys).to include('ducks', 'crows')
      expect(inventory3.children['birds']).to include('ducks', 'crows')
    end
  end

  describe '#hostvars' do
    it "returns a hash each host's hostvars mapped to its inventory hostname"
  end

  describe '#validate!' do
    context 'when nonextant children are defined for a group' do
      it 'raises an error' do
        inventory.groups = ['parent']
        inventory.children_of('parent', 'child')
        expect { inventory.validate! }.to raise_error(
          VagrantPlugins::AnsibleAuto::Errors::GroupMissingChildError,
          /group parent defines nonextant child group child/
        )
      end
    end
  end

  describe '#to_ini' do
    include_context 'host'

    let(:host1) do
      VagrantPlugins::AnsibleAuto::Host.new('blurgh').tap do |h|
        h.inventory_hostname            = 'tweedledee'
        h.ansible_ssh_user              = 'me'
        h.ansible_ssh_host              = '10.10.0.20'
        h.ansible_ssh_port              = 2200
        h.ansible_ssh_private_key_file  = 'me_id_rsa'
      end
    end

    let(:host2) do
      VagrantPlugins::AnsibleAuto::Host.new('bleh').tap do |h|
        h.inventory_hostname            = 'tweedledum'
        h.ansible_ssh_user              = 'you'
        h.ansible_ssh_host              = '192.168.1.88'
        h.ansible_ssh_port              = 2201
        h.ansible_ssh_private_key_file  = 'you_id_rsa'
      end
    end

    it 'returns the inventory as an INI-style document' do
      inventory.add_group(:mygroup, complex_group)
      inventory.add_host(host1)
      inventory.add_host(host2)
      expect(inventory.to_ini).to eq(unindent(<<-INVENTORY).chomp)
        tweedledee ansible_ssh_host=10.10.0.20 ansible_ssh_port=2200 ansible_ssh_private_key_file=me_id_rsa ansible_ssh_user=me
        tweedledum ansible_ssh_host=192.168.1.88 ansible_ssh_port=2201 ansible_ssh_private_key_file=you_id_rsa ansible_ssh_user=you
        [mygroup]
        bastion
        db
        firewall
        [mygroup:children]
        qa
        staging
        [mygroup:vars]
        n = uh
        this = n
        uh = that
      INVENTORY
    end
  end
end
