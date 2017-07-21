# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/config'

describe VagrantPlugins::AnsibleAuto::Config do
  include_context 'config'

  describe '#validate' do
    context 'given a non-boolean value for #strict_host_key_checking' do
      it 'catches the error and reutrns it under the "ansible_auto" key' do
        config.strict_host_key_checking = 5
        config.finalize!
        errors = config.validate(machine)
        expect(errors['ansible_auto']).to include('strict_host_key_checking must be either true or false')
      end
    end

    context 'given an error constructing the inventory' do
      it 'catches the error and returns it under the "ansible_auto" key' do
        pending 'at the moment, the inventory object does not raise any errors along the relevant code paths' do
          config.finalize!
          errors = config.validate(machine)
          expect(errors['ansible_auto']).not_to be_empty
        end
      end
    end
  end
end
