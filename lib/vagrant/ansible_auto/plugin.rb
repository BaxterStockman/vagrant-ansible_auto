# frozen_string_literal: true

load 'vagrant/ansible_auto.rb'

# Namespace for Vagrant plugins
module VagrantPlugins
  # Namespace for the +ansible_auto+ provisioner and +ansible+ command
  module AnsibleAuto
    # Vagrant plugin class for the +ansible_auto+ provisioner and +ansible+
    # command
    class Plugin < Vagrant.plugin(2)
      name 'ansible auto'
      description <<-DESC
      Automatically generate Ansible inventories for use when running Ansible
      on guest machines
      DESC

      def self.init!
        require 'i18n'

        VagrantPlugins::AnsibleAuto.source_root.join('locales/en.yml').tap do |en|
          I18n.load_path << en unless I18n.load_path.include? en
          I18n.reload!
        end
      end

      config 'ansible' do
        require_relative 'config'
        Config
      end

      command 'ansible' do
        require_relative 'command/root'
        Command::Root
      end

      config('ansible_auto', :provisioner) do
        require_relative 'config'
        Config
      end

      provisioner 'ansible_auto' do
        require_relative 'provisioner'
        Provisioner
      end

      # Compatibility with Vagrantfiles from before name change to ansible_auto
      config('ansible_inventory', :provisioner) do
        require_relative 'config'
        Config
      end

      provisioner 'ansible_inventory' do
        require_relative 'provisioner'
        Provisioner
      end

      guest_capability 'linux', :port_open? do
        require_relative 'cap/guest/posix/check_open_port'
        Cap::Guest::POSIX::CheckOpenPort
      end

      guest_capability 'linux', :gateway_addresses do
        require_relative 'cap/guest/posix/gateway_addresses'
        Cap::Guest::POSIX::GatewayAddresses
      end

      guest_capability 'linux', :ssh_server_address do
        require_relative 'cap/guest/posix/ssh_server_address'
        Cap::Guest::POSIX::SSHServerAddress
      end

      guest_capability 'linux', :executable_installed? do
        require_relative 'cap/guest/posix/executable_installed'
        Cap::Guest::POSIX::ExecutableInstalled
      end

      guest_capability 'linux', :generate_private_key do
        require_relative 'cap/guest/posix/private_key'
        Cap::Guest::POSIX::PrivateKey
      end

      guest_capability 'linux', :fetch_public_key do
        require_relative 'cap/guest/posix/public_key'
        Cap::Guest::POSIX::PublicKey
      end

      guest_capability 'linux', :authorized_key? do
        require_relative 'cap/guest/posix/public_key'
        Cap::Guest::POSIX::PublicKey
      end

      action_hook 'environment_plugins_loaded' do
        init!
      end
    end
  end
end
