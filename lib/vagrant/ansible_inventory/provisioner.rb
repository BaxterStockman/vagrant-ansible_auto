require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/provisioner/guest'

module VagrantPlugins
  module AnsibleInventory
    class Provisioner < VagrantPlugins::Ansible::Provisioner::Guest
      include Vagrant::Util::Retryable

      def configure(root_config)
        super
        @__ansible_config = root_config.ansible
      end

      def provision
        @config = @__ansible_config.merge(config)

        # TODO figure out how to access ansible_inventory configuration done
        # on the `other' machine.
        #@config = other.config.ansible.merge(merged_config)
        if machine.guest.capability?(:ssh_server_address)
          with_active_machines do |other, name, provider|
            # We're dealing with the machine doing the provisining
            if name == machine.name
              other_hostvars = {:connection => 'local'}
            elsif other.nil?
              machine.ui.warn "Machine #{name} is not configured for this environment; omitting it from the inventory"
            else
              # The machines we are trying to manage might not yet be ready to
              # connect -- retry a configurable number of times/durations until
              # we can connect; otherwise raise an exception.
              other_ssh_info = nil
              retryable(on: Vagrant::Errors::SSHNotReady, tries: @config.host_connect_tries, sleep: @config.host_connect_sleep) do
                other_ssh_info = other.ssh_info
                raise Vagrant::Errors::SSHNotReady if other_ssh_info.nil?
              end

              ssh_host, ssh_port = machine.guest.capability(:ssh_server_address, other)
              other_hostvars = {ssh_host: ssh_host, ssh_port: ssh_port}

              # TODO warn about empty :private_key_path array
              other.ssh_info.fetch(:private_key_path, []).each do |source_key|
                remote_key_path = File.join(@config.tmp_path, 'ssh', name.to_s, provider.to_s, File.basename(source_key))
                other_hostvars[:ssh_private_key_file] = remote_key_path
                create_and_chown_remote_folder(File.dirname(remote_key_path))
                machine.communicate.upload(source_key, remote_key_path)
              end
            end

            @config.inventory.add_host(other, other_hostvars || Hash.new)
          end
        end

        super
      end

    private

      def generate_inventory_machines
        if config.strict_host_key_checking
          machine_format = '%s'
        else
          machine_format = "%s ansible_ssh_extra_args='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'"
        end

        config.inventory.with_ini_lines_hosts.map do |host_spec|
          machine_format % host_spec
        end.join("\n") + "\n"
      end

      def generate_inventory_groups
        config.inventory.with_ini_lines_groups.to_a.join("\n") + "\n"
      end

      def with_active_machines
        return enum_for(__method__) unless block_given?

        machine.env.active_machines.each do |name, provider|
          begin
            yield machine.env.machine(name, provider), name, provider
          rescue Vagrant::Errors::MachineNotFound, CommunicatorWinRM::Errors::WinRMNotReady => e
            machine.ui.warn "unable to find machine #{name} (#{e.message})"
            return nil, name, provider
          end
        end
      end

      # TODO
      #   - just use first key?
      #   - check if host.ansible_private_key_path already exists on
      #     the remote machine?
      def create_and_chown_remote_private_key(other, private_key_file, name, provider)
        #
        other.ssh_info.fetch(:private_key_path, []).compact.each do |source_key|
          create_and_chown_remote_folder(File.dirname(private_key_file))
          machine.communicate.upload(source_key, private_key_file)
        end
      end
    end
  end
end
