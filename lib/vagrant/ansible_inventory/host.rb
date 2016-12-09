module VagrantPlugins
  module AnsibleInventory
    class Host
      ANSIBLE_HOSTVARS = [:ssh_user, :ssh_host, :ssh_port, :ssh_private_key_file, :connection]

      attr_writer(*ANSIBLE_HOSTVARS)

      def initialize(name, hostvars={})
        @name = name

        # Convert keys to symbols
        @hostvars = hostvars.each_with_object({}) { |(k, v), acc| acc[k.to_sym] = v }
      end

      def name
        @name ||= 'default'
      end

      def ssh_user
        @ssh_user ||= @hostvars[:ssh_user] || 'vagrant'
      end

      def ssh_host
        @ssh_host ||= @hostvars[:ssh_host] || '127.0.0.1'
      end

      def ssh_port
        @ssh_port ||= @hostvars[:ssh_port] || 22
      end

      def ssh_private_key_file
        @ssh_private_key_file ||= @hostvars[:ssh_private_key_file]
      end

      def connection
        @connection ||= @hostvars[:connection]
      end

      def hostvars
        ANSIBLE_HOSTVARS.each_with_object({}) do |m, acc|
          value = send(m)
          acc["ansible_#{m}"] = value unless value.nil?
        end
      end

      def to_h
        {name => hostvars}
      end

      def to_ini
        [name, *hostvars.reject {|_, value| value.nil? }.map { |key, value| "#{key}=#{value}" }].join(' ')
      end
    end

    class HostMachine < Host
      def initialize(machine, hostvars={})
        super(machine.name, hostvars)
        @machine = machine
        @ssh_info = machine.ssh_info || Hash.new
      end

      def ssh_user
        @ssh_user ||= @hostvars[:ssh_user] || @ssh_info[:username] || super
      end

      def ssh_host
        @ssh_host ||= @hostvars[:ssh_host] || @ssh_info[:host] || super
      end

      def ssh_port
        @ssh_port ||= @hostvars[:ssh_port] || @ssh_info[:port] || super
      end

      # TODO better inference of which private key to use
      def ssh_private_key_file
        @ssh_private_key_file ||= @hostvars[:ssh_private_key_file] || @ssh_info.fetch(:private_key_path, []).first || super
      end
    end
  end
end
