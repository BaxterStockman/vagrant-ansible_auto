# frozen_string_literal: true
module VagrantPlugins
  module AnsibleAuto
    module Errors
      class InventoryError < Vagrant::Errors::VagrantError
        error_namespace('vagrant.provisioners.ansible_auto')
      end

      class MissingGroupError < InventoryError
        error_key(:missing_group)
      end
    end
  end
end
