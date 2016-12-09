module VagrantPlugins
  module AnsibleInventory
    module Util
      # Adapted from VagrantPlugins::CommunicatorSSH::Communicator#insecure_key?.
      # This will test whether +path+ is the Vagrant insecure private key.
      #
      # @param [String] path
      def insecure_key?(path)
        return false if path.nil? or !File.file?(path)
        @__insecure_key ||= Vagrant.source_root.join('keys/vagrant').read.chomp
        return File.read(path).chomp == @_insecure_key
      end

      def fetch_private_key(machine)
        if machine.config.ssh.insert_key
          return machine.ssh_info.fetch(:private_key_path, []).find { |k| !insecure_key?(k) }
        else
          return machine.env.default_private_key_path
        end
      end
    end
  end
end
