require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/provisioner/guest'

module VagrantPlugins
  module AnsibleInventory
    class Provisioner < VagrantPlugins::Ansible::Provisioner::Guest
      def configure(root_config)
        super
        @__ansible_config = root_config.ansible
      end

      def provision
        merged_config = @__ansible_config.merge(config)

        if machine.guest.capability?(:ssh_server_address)
          with_active_machines do |other, name, provider|
            if name == machine.name
              other_hostvars = {:connection => 'local'}
            else
              ssh_host, ssh_port = machine.guest.capability(:ssh_server_address, other)
              other_hostvars = {ssh_host: ssh_host, ssh_port: ssh_port}

              # TODO just use first key?
              other.ssh_info.fetch(:private_key_path, []).each do |source_key|
                remote_key_path = File.join(merged_config.tmp_path, 'ssh', name.to_s, provider.to_s, File.basename(source_key))
                other_hostvars[:ssh_private_key_file] = remote_key_path
                create_and_chown_remote_folder(File.dirname(remote_key_path))
                machine.communicate.upload(source_key, remote_key_path)
              end
            end

            merged_config.inventory.add_host(other, other_hostvars)

            # TODO figure out how to access ansible_inventory configuration done
            # on the `other' machine.
            #merged_config = other.config.ansible.merge(merged_config)
          end
        end

        @config = merged_config

        super
      end

    private

      def generate_inventory_machines
        config.inventory.with_ini_lines_hosts.map do |host_spec|
          "#{host_spec} ansible_ssh_extra_args='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'"
        end.join("\n") + "\n"
      end

      def generate_inventory_groups
        config.inventory.with_ini_lines_groups.to_a.join("\n") + "\n"
      end

      def with_active_machines
        return enum_for(__method__) unless block_given?

        machine.env.active_machines.each do |name, provider|
          yield machine.env.machine(name, provider), name, provider
        end
      end
    end
  end
end
