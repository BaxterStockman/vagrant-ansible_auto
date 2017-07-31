# frozen_string_literal: true

require 'optparse'

module VagrantPlugins
  module AnsibleAuto
    module Command
      # Vagrant +ansible inventory+ subcommand
      class Inventory < Vagrant.plugin(2, :command)
        # @return [String] summary of the +ansible inventory+ command
        def self.synopsis
          I18n.t('vagrant.ansible_auto.command.inventory.synopsis')
        end

        # Print the Ansible inventory for the current Vagrantfile.
        #
        # By default, the inventory is printed in Ansible's static INI
        # inventory style.  When the +-l/--list+ flag is present, the inventory
        # is printed in Ansible's dynamic JSON inventory style.
        #
        # @return [Integer] the exit status of the command
        def execute
          operation = :as_ini

          opts = OptionParser.new do |op|
            op.banner = I18n.t('vagrant.ansible_auto.command.inventory.usage')
            op.separator ''
            op.separator I18n.t('vagrant.ansible_auto.command.inventory.available_options')

            op.on('--ini', I18n.t('vagrant.ansible_auto.command.inventory.option.ini')) do
              operation = :as_ini
            end

            op.on('--json', I18n.t('vagrant.ansible_auto.command.inventory.option.json')) do
              operation = :as_json
            end

            op.on('--pretty', I18n.t('vagrant.ansible_auto.command.inventory.option.pretty')) do
              operation = :as_pretty_json
            end
          end

          machines = parse_options(opts)

          @env.ui.info send(operation, machines), prefix: false unless machines.nil?

          0
        end

      private

        def as_ini(machines)
          build_inventory(machines).to_ini
        end

        def as_json(machines)
          build_inventory(machines).to_json
        end

        def as_pretty_json(machines)
          JSON.pretty_generate(build_inventory(machines))
        end

        def build_inventory(machines)
          with_target_vms(machines) {}.each_with_object(AnsibleAuto::Inventory.new) do |machine, inventory|
            unless machine.state.id == :running
              @env.ui.warn I18n.t('vagrant.ansible_auto.command.inventory.diag.not_running', machine_name: machine.name), channel: :error
            end

            inventory.merge!(machine.config.ansible.inventory)
            inventory.add_host(machine)
          end
        end
      end
    end
  end
end
