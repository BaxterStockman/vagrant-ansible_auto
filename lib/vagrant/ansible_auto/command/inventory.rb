# frozen_string_literal: true
require 'optparse'

module VagrantPlugins
  module AnsibleAuto
    module Command
      class Inventory < Vagrant.plugin(2, :command)
        def self.synopsis
          'dynamic ansible inventory'
        end

        def execute
          opts = OptionParser.new do |op|
            op.banner = 'Usage: vagrant ansible inventory [<options>]'
            op.separator ''
            op.separator 'Available options:'

            op.on('-l', '--list', 'List all hosts as json') do |_target|
              @env.ui.info inventory.to_json, prefix: false
              return 0
            end

            op.on('-h', '--help', 'Show this message') do
              @env.ui.info opts.help, prefix: false
              return 0
            end
          end

          @argv = parse_options(opts)

          @env.ui.info inventory.to_ini, prefix: false

          0
        end

      private

        def inventory
          @inventory = with_target_vms(@argv) {}.each_with_object(AnsibleAuto::Inventory.new) do |machine, inventory|
            unless machine.state.id == :running
              @env.ui.warn "machine #{machine.name} is not running; falling back to default hostvar values"
            end
            inventory.merge!(machine.config.ansible.inventory)
            inventory.add_host(machine)
          end
        end
      end
    end
  end
end
