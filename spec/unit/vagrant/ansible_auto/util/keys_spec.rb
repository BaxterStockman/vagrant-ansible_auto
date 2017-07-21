# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/util/keys'

describe VagrantPlugins::AnsibleAuto::Util::Keys do
  include_context 'machine'

  let(:including_klass) do
    Class.new do
      include VagrantPlugins::AnsibleAuto::Util::Keys
    end
  end

  let(:including_instance) { including_klass.new }

  let(:fake_private_key_path) { temporary_file('+-----NOT AN RSA PRIVATE KEY-----+') }

  describe '#insecure_key_path' do
    it 'returns the path to the Vagrant insecure key' do
      expect(including_instance.insecure_key_path).to be_a Pathname
    end
  end

  describe '#insecure_key_contents' do
    it 'returns the contents of the Vagrant insecure key' do
      expect(including_instance.insecure_key_contents).to be_a String
      expect(including_instance.insecure_key_contents).to include('BEGIN RSA PRIVATE KEY')
    end
  end

  describe '#insecure_key?' do
    it 'indicates whether the provided key file contains the Vagrant insecure key' do
      expect(including_instance.insecure_key?(including_instance.insecure_key_path)).to be true
      expect(including_instance.insecure_key?(fake_private_key_path)).to be false
    end
  end

  describe '#fetch_private_key' do
    context 'given a machine with no private keys configured' do
      before do
        allow(machine).to receive(:ssh_info).and_return(nil)
        allow(machine.config.ssh).to receive(:insert_key).and_return(true)
      end

      it "returns the machine's default private key" do
        expect(including_instance.fetch_private_key(machine)).to eq(machine.env.default_private_key_path)
      end
    end

    context 'given a machine with at least one private key configured' do
      let(:private_key_paths) do
        [including_instance.insecure_key_path, fake_private_key_path]
      end

      before do
        allow(ssh_info).to receive(:fetch).with(:private_key_path, anything).and_return(private_key_paths)
      end

      it "returns the first of the machine's private keys that is not the Vagrant insecure key" do
        expect(including_instance.fetch_private_key(machine)).to eq(fake_private_key_path)
      end
    end
  end
end
