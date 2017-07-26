# frozen_string_literal: true
require 'vagrant/ansible_auto/inventory'
require 'vagrant/ansible_auto/errors'
require 'vagrant/util/deep_merge'

require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/config/guest'

module VagrantPlugins
  module AnsibleAuto
    class Config < VagrantPlugins::Ansible::Config::Guest
      attr_accessor :inventory, :groups, :vars, :children,
                    :strict_host_key_checking, :host_connect_tries, :host_connect_sleep

      protected(:inventory=)

      def initialize
        super
        @inventory                = Inventory.new
        @groups                   = UNSET_VALUE
        @vars                     = UNSET_VALUE
        @children                 = UNSET_VALUE
        @strict_host_key_checking = UNSET_VALUE
        @host_connect_tries       = UNSET_VALUE
        @host_connect_sleep       = UNSET_VALUE
        @__errors                 = []
      end

      def finalize!
        super
        @inventory.groups         = @groups   unless @groups                == UNSET_VALUE
        @inventory.vars           = @vars     unless @vars                  == UNSET_VALUE
        @inventory.children       = @children unless @children              == UNSET_VALUE
        @strict_host_key_checking = false     if @strict_host_key_checking  == UNSET_VALUE
        @host_connect_tries       = 10        if @host_connect_tries        == UNSET_VALUE
        @host_connect_sleep       = 2         if @host_connect_sleep        == UNSET_VALUE
      rescue Errors::InventoryError => e
        @__errors << e.message
      end

      def validate(machine)
        super

        errors = _detected_errors + @__errors

        # TODO: -- test that `host_wait...' values are integers
        unless @strict_host_key_checking == true or @strict_host_key_checking == false
          errors << "strict_host_key_checking must be either true or false"
        end

        { 'ansible_auto' => errors }
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
    end
  end
end
