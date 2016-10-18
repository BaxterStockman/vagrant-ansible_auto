module VagrantPlugins
  module AnsibleInventory
    module Errors
      class AnsibleInventoryError < Vagrant::Errors::VagrantError
        error_namespace('vagrant.provisioners.ansible_inventory')
      end

      class MissingGroupError < AnsibleInventoryError
        error_key(:missing_group)
      end
    end
  end
end
