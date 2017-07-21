# frozen_string_literal: true

require 'pathname'

require 'vagrant'

require 'vagrant/ansible_auto/plugin'
require 'vagrant/ansible_auto/version'

module VagrantPlugins
  # Ansible command and provisioner plugin with automatic inventory generation
  module AnsibleAuto
    class << self
      # @return [Pathname] path to the gem source root directory
      def source_root
        Pathname.new('../../..').expand_path(__FILE__)
      end
    end
  end
end
