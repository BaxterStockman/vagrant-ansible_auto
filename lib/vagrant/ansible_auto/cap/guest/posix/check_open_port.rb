# frozen_string_literal: true

require 'uri'

require 'vagrant/ansible_auto/util/shell_quote'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          # Capability class for checking whether a port is open on a given
          # host
          # @note requires Bash to be installed on the target machine
          class CheckOpenPort
            extend VagrantPlugins::AnsibleAuto::Util::ShellQuote

            class << self
              # Check whether a port is open
              # @param [Vagrant::Machine] machine a guest machine
              # @param [String] host hostname whose port will be checked
              # @param [Integer] port port number to check
              # @param [String] proto the protocol to use
              # @return [Boolean] if a valid hostname and port were provided,
              #   whether the specified port is open on the specified host
              # @return [nil] if hostname or port were not valid, or if Bash is
              #   not available on the target machine
              def port_open?(machine, host, port, proto = 'tcp')
                return nil unless machine.communicate.test('bash')

                # Check that we got a valid URI by constructing a URI object
                # and watching for exceptions raised upon component assignment.
                begin
                  uri = URI('').tap do |u|
                    u.host = host
                    u.port = port
                  end
                rescue URI::InvalidComponentError
                  return nil
                end

                return false if uri.host.nil? || uri.port.nil?

                target = shellescape(File.join('/dev/', proto, uri.host, uri.port.to_s))
                machine.communicate.test("read < #{target}", shell: 'bash')
              end
            end
          end
        end
      end
    end
  end
end
