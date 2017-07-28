# frozen_string_literal: true

require 'spec_helper'

require 'vagrant/ansible_auto/config'

describe VagrantPlugins::AnsibleAuto::Config do
  include_context 'config'

  def validate_config(c, m, attr, v)
    c.public_send("#{attr}=", v)
    c.finalize!
    errors = c.validate(m)
    yield errors['ansible_auto']
  end

  describe '#validate' do
    context 'given an invalid value for a configuration parameter' do
      it 'catches the error and returns it under the "ansible_auto" key' do
        described_class::BOOLEAN.each do |attr|
          validate_config(config, machine, attr, 5) do |errors|
            expect(errors).to include("#{attr} must be either true or false")
          end
        end

        described_class::INTEGER.each do |attr|
          validate_config(config, machine, attr, nil) do |errors|
            expect(errors).to include("#{attr} must be an integer")
          end
        end

        described_class::NUMBER.each do |attr|
          validate_config(config, machine, attr, nil) do |errors|
            expect(errors).to include("#{attr} must be a number")
          end
        end
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

    context 'given a valid value for a configuration parameter' do
      it 'does not catch the error and return it under the "ansible_auto" key' do
        described_class::BOOLEAN.each do |attr|
          validate_config(config, machine, attr, true) do |errors|
            expect(errors).not_to include("#{attr} must be either true or false")
          end
        end

        described_class::INTEGER.each do |attr|
          validate_config(config, machine, attr, 10) do |errors|
            expect(errors).not_to include("#{attr} must be an integer")
          end
        end

        described_class::NUMBER.each do |attr|
          validate_config(config, machine, attr, 3.14159) do |errors|
            expect(errors).not_to include("#{attr} must be a number")
          end
        end
      end
    end
  end
end
