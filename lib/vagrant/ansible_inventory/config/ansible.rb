require 'vagrant/ansible_inventory/inventory'
require 'vagrant/ansible_inventory/errors'
require 'vagrant/util/deep_merge'

require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/config/guest'

module VagrantPlugins
  module AnsibleInventory
    module Config
      class Ansible < VagrantPlugins::Ansible::Config::Guest
        attr_accessor :inventory, :groups, :vars, :children, :tmp_path

        def initialize
          super
          @inventory  = Inventory.new
          @groups     = UNSET_VALUE
          @vars       = UNSET_VALUE
          @children   = UNSET_VALUE
          @tmp_path   = UNSET_VALUE
          @__errors   = []
        end

        def finalize!
          super
          @inventory.groups   = @groups unless @groups == UNSET_VALUE
          @inventory.vars     = @vars unless @vars == UNSET_VALUE
          @inventory.children = @children unless @children == UNSET_VALUE
          @tmp_path = '/vagrant/ansible' if @tmp_path == UNSET_VALUE
        rescue Errors::InventoryError => e
          @__errors << e.message
        end

        def validate(machine)
          super

          errors = _detected_errors + @__errors

          # TODO

          {'ansible_inventory' => errors}
        end

        def merge(other)
          return super if other.nil?

          super.tap do |result|
            result.groups     = conditional_merge(groups, other.groups)
            result.vars       = conditional_merge(vars, other.vars)
            result.children   = conditional_merge(children, other.children)
            result.inventory  = inventory.merge(other.inventory)
          end
        end

      private

        def conditional_merge(a, b)
          if b.nil? or b == UNSET_VALUE
            return a
          elsif a.nil? or a == UNSET_VALUE
            return b
          else
            return Vagrant::Util::DeepMerge.deep_merge(a, b)
          end
        end
      end
    end
  end
end
