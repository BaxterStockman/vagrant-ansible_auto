# frozen_string_literal: true

require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/config/guest'

require 'vagrant/ansible_auto/inventory'
require 'vagrant/ansible_auto/errors'
require 'vagrant/ansible_auto/util/config'

module VagrantPlugins
  module AnsibleAuto
    # Configuration for the +ansible_auto+ provisioner and +ansible+ command
    class Config < VagrantPlugins::Ansible::Config::Guest
      include Util::Config

      attr_accessor :inventory, :groups, :vars, :children,
                    :strict_host_key_checking, :host_connect_tries,
                    :host_connect_sleep, :insert_control_machine_public_key,
                    :upload_inventory_host_private_keys

      protected(:inventory=)

      BOOLEAN = %I[
        strict_host_key_checking
        insert_control_machine_public_key
        upload_inventory_host_private_keys
      ].freeze

      INTEGER = %I[
        host_connect_tries
      ].freeze

      NUMBER = %I[
        host_connect_sleep
      ].freeze

      def initialize
        super
        @inventory                          = Inventory.new
        @groups                             = UNSET_VALUE
        @vars                               = UNSET_VALUE
        @children                           = UNSET_VALUE
        @strict_host_key_checking           = UNSET_VALUE
        @host_connect_tries                 = UNSET_VALUE
        @host_connect_sleep                 = UNSET_VALUE
        @insert_control_machine_public_key  = UNSET_VALUE
        @upload_inventory_host_private_keys = UNSET_VALUE
        @__errors = []
      end

      # Set default configuration values at the end of constructing the Vagrant
      # environment
      # @api private
      # @return [void]
      def finalize!
        super
        @inventory.groups                   = @groups                             unless @groups                          == UNSET_VALUE
        @inventory.vars                     = @vars                               unless @vars                            == UNSET_VALUE
        @inventory.children                 = @children                           unless @children                        == UNSET_VALUE
        @strict_host_key_checking           = false                               if @strict_host_key_checking            == UNSET_VALUE
        @host_connect_tries                 = 10                                  if @host_connect_tries                  == UNSET_VALUE
        @host_connect_sleep                 = 2                                   if @host_connect_sleep                  == UNSET_VALUE
        @insert_control_machine_public_key  = true                                if @insert_control_machine_public_key   == UNSET_VALUE
        @upload_inventory_host_private_keys = !@insert_control_machine_public_key if @upload_inventory_host_private_keys  == UNSET_VALUE

        # NOTE @limit is defined in core Vagrant's Ansible config.
        @limit = '*' if @limit == UNSET_VALUE
      rescue Errors::InventoryError => e
        @__errors << e.message
      end

      # Ensure that the configuration is in a valid state
      # @api private
      # @return [Hash{String=>Array}] a structure containing a list of errors
      #   under the +ansible_auto+ key
      def validate(machine)
        super

        errors = _detected_errors + @__errors

        BOOLEAN.each do |o|
          unless bool? instance_variable_get(:"@#{o}")
            errors << "#{o} must be either true or false"
          end
        end

        INTEGER.each do |o|
          unless int? instance_variable_get(:"@#{o}")
            errors << "#{o} must be an integer"
          end
        end

        NUMBER.each do |o|
          unless num? instance_variable_get(:"@#{o}")
            errors << "#{o} must be a number"
          end
        end

        { 'ansible_auto' => errors }
      end

      # Merge two configurations
      # @api private
      # @param [Config] other the configuration to merge into this
      #   configuration
      # @return [Config] the merged configuration
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
