module VagrantPlugins
  module AnsibleInventory
    class Plugin < Vagrant.plugin(2)

      name 'ansible inventory'

      config 'ansible' do
        require_relative 'config'
        Config
      end

      command 'ansible' do
        require_relative 'command/root'
        Command::Root
      end

      config('ansible_inventory', :provisioner) do
        require_relative 'config'
        Config
      end

      provisioner 'ansible_inventory' do
        require_relative 'provisioner'
        Provisioner
      end

      guest_capability 'linux', :check_open_port do
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

      guest_capability 'linux', :bash_installed? do
        require_relative 'cap/guest/posix/bash_installed'
        Cap::Guest::POSIX::BashInstalled
      end
    end
  end
end
