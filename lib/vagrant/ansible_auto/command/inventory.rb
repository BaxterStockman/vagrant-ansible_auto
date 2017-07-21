# frozen_string_literal: true

require 'optparse'

module VagrantPlugins
  module AnsibleAuto
    module Command
      # Vagrant +ansible inventory+ subcommand
      class Inventory < Vagrant.plugin(2, :command)
        # @return [String] summary of the +ansible inventory+ command
        def self.synopsis
          'dynamic ansible inventory'
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
            op.banner = 'Usage: vagrant ansible inventory [<options>]'
            op.separator ''
            op.separator 'Available options:'

            op.on('-l', '--list', 'List all hosts as JSON') do
              operation = :as_json
            end

            # TODO: set up JSON pretty printing of JSON
            op.on('--pretty', 'Use pretty JSON output') do
              operation = :as_pretty_json
            end
          end

          machines = parse_options(opts)

          @env.ui.info send(operation, machines), prefix: false

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
              @env.ui.warn "machine #{machine.name} is not running; falling back to default hostvar values", channel: :error
            end
            inventory.merge!(machine.config.ansible.inventory)
            inventory.add_host(machine)
          end
        end
      end
    end
  end
end
