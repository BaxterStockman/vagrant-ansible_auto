# frozen_string_literal: true

module VagrantPlugins
  module AnsibleAuto
    # Error classes for the +ansible_auto+ provisioner and +ansible+ command
    module Errors
      # An error representing an {Inventory} misconfiguration
      class InventoryError < Vagrant::Errors::VagrantError
        error_namespace('vagrant.ansible_auto.errors.inventory')
      end

      # Raised when an Ansible inventory group is expected to exist but doesn't
      class MissingGroupError < InventoryError
        error_key(:missing_group)
      end

      # Raised when a group specifies child groups that do not exist
      class GroupMissingChildError < MissingGroupError
        error_key(:group_missing_child)
      end

      # Raised when provided data can't be converted to a {Host} object
      class InvalidHostTypeError < InventoryError
        error_key(:invalid_host_type)
      end

      class CommandError < Vagrant::Errors::VagrantError
        error_namespace('vagrant.ansible_auto.errors.command')
      end

      class UnrecognizedCommandError < CommandError
        error_key('unrecognized_command')
      end
    end
  end
end
