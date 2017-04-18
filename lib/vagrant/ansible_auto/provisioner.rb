# frozen_string_literal: true
require 'vagrant'
require Vagrant.source_root + 'plugins/provisioners/ansible/provisioner/guest'
require 'vagrant/util/keypair'

require 'vagrant/ansible_auto/util'

require 'log4r'
require 'shellwords'

module VagrantPlugins
  module AnsibleAuto
    class Provisioner < VagrantPlugins::Ansible::Provisioner::Guest
      include Vagrant::Util::Retryable
      include VagrantPlugins::AnsibleAuto::Util

      def initialize(machine, config)
        super
        @logger = Log4r::Logger.new('vagrant::provisioners::ansible_auto')
      end

      def configure(root_config)
        super
        @__ansible_config = root_config.ansible
      end

      def provision
        @config = @__ansible_config.merge(config)

        remote_priv_key_path, remote_pub_key_path, openssh = configure_keypair!

        # TODO: figure out how to access ansible_auto configuration done
        # on the `other' machine.
        # @config = other.config.ansible.merge(merged_config)
        if machine.guest.capability?(:ssh_server_address)

          with_active_machines do |other, name, provider|
            # We're dealing with the machine doing the provisining
            if name == machine.name
              other_hostvars = { connection: 'local' }
            elsif other.nil?
              machine.ui.warn "Machine #{name} is not configured for this environment; omitting it from the inventory"
            else
              # The machines we are trying to manage might not yet be ready to
              # connect -- retry a configurable number of times/durations until
              # we can connect; otherwise raise an exception.
              private_key_paths = []
              retryable(on: Vagrant::Errors::SSHNotReady, tries: @config.host_connect_tries, sleep: @config.host_connect_sleep) do
                raise Vagrant::Errors::SSHNotReady unless other.communicate.ready? and !other.ssh_info.nil?

                private_key_paths = other.ssh_info.fetch(:private_key_path, [])
                raise Vagrant::Errors::SSHNotReady if private_key_paths.empty?

                if other.config.ssh.insert_key
                  raise Vagrant::Errors::SSHNotReady unless private_key_paths.any? { |k| !insecure_key?(k) }
                end
              end

              ssh_host, ssh_port = machine.guest.capability(:ssh_server_address, other)
              other_hostvars = { ssh_host: ssh_host, ssh_port: ssh_port }

              if private_key_paths.empty?
                machine.ui.warn "No private keys available for machine #{name}; provisioner will likely fail"
              end

              source_priv_key_path = fetch_private_key(other)

              if source_priv_key_path.nil?
                machine.ui.warn "Private key for #{name} not available for upload; provisioner will likely fail"
              else
                machine.ui.info "Adding #{name} to Ansible inventory"

                if other.guest.capability?(:insert_public_key)
                  other.guest.capability(:insert_public_key, openssh)
                else
                  remote_priv_key_path = File.join(@config.tmp_path, 'ssh', name.to_s, provider.to_s, File.basename(source_priv_key_path))
                  create_and_chown_and_chmod_remote_file(source_priv_key_path, remote_priv_key_path)
                end

                other_hostvars[:ssh_private_key_file] = remote_priv_key_path
              end
            end

            @config.inventory.add_host(other, other_hostvars || {})
          end
        end

        super
      end

    private

      def configure_keypair!
        # FIXME
        remote_priv_key_path = "~#{machine.ssh_info[:username]}/.ssh/id_rsa"
        remote_pub_key_path = "#{remote_priv_key_path}.pub"

        # Check whether user has a private key already
        if !machine.communicate.test("test -f #{remote_priv_key_path}") or !machine.communicate.test("test -f #{remote_pub_key_path}")
          _pub, _priv, openssh = Vagrant::Util::Keypair.create
          write_and_chown_and_chmod_remote_file(priv, remote_priv_key_path)
          write_and_chown_and_chmod_remote_file(openssh, remote_pub_key_path)
        else
          if machine.guest.capability?(:fetch_public_key)
            openssh = machine.guest.capability(:fetch_public_key, remote_priv_key_path)
          end
        end

        return remote_priv_key_path, remote_pub_key_path, openssh
      end

      def handle_remote_file(to, owner = machine.ssh_info[:username], mode = 0600)
        machine.communicate.tap do |comm|
          create_and_chown_remote_folder(File.dirname(to))

          yield comm, to

          comm.sudo("chown -h #{machine.ssh_info[:username]} #{to}")
          comm.sudo("chmod #{'0%o' % mode} #{to}")
        end
      end

      def create_and_chown_and_chmod_remote_file(from, to, mode = 0600)
        handle_remote_file(to, mode) do |comm, target|
          comm.upload(from, target)
        end
      end

      def write_and_chown_and_chmod_remote_file(contents, to, mode = 0600)
        handle_remote_file(to, mode) do |comm, target|
          contents = contents.strip << "\n"

          to_parent = File.dirname(to)

          remote_path = "/tmp/vagrant-temp-asset-#{Time.now.to_i}"
          Tempfile.open("vagrant-temp-asset") do |f|
            f.binmode
            f.write(contents)
            f.fsync
            f.close
            machine.ui.info("uploading #{f.path} to #{remote_path}")
            comm.upload(f.path, remote_path)
          end

          # FIXME configure perms on parent dir
          comm.execute <<-EOH.gsub(/^ */, "")
            mkdir #{to_parent}
            mv #{remote_path} #{to}
          EOH
        end
      end

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
    end
  end
end
