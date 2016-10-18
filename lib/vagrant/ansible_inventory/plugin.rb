module VagrantPlugins
  module AnsibleInventory
    class Plugin < Vagrant.plugin(2)

      name 'ansible inventory'

      config 'ansible' do
        require_relative 'config/ansible'
        Config::Ansible
      end

      command 'ansible' do
        require_relative 'command/root'
        Command::Root
      end

      config('ansible_inventory', :provisioner) do
        require_relative 'config/ansible'
        Config::Ansible
      end

      provisioner 'ansible_inventory' do
        require_relative 'provisioner'
        Provisioner
      end

      guest_capability 'linux', :check_open_port do
        require_relative 'cap/guest/linux/check_open_port'
        Cap::Guest::Linux::CheckOpenPort
      end

      guest_capability 'linux', :gateway_addresses do
        require_relative 'cap/guest/linux/gateway_addresses'
        Cap::Guest::Linux::GatewayAddresses
      end

      guest_capability 'linux', :ssh_server_address do
        require_relative 'cap/guest/linux/ssh_server_address'
        Cap::Guest::Linux::SSHServerAddress
      end
    end
  end
end
