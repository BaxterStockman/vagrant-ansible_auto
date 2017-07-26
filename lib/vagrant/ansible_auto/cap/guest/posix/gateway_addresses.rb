# frozen_string_literal: true
require 'set'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          class GatewayAddresses
            class << self
              def gateway_addresses(machine)
                with_default_gateway_addresses(machine).to_a.compact
              end

            private

              def with_default_gateway_addresses(machine)
                return enum_for(__method__, machine) unless block_given?

                machine.communicate.execute('ip route show', error_check: false) do |type, data|
                  if type == :stdout
                    data.each_line { |l| yield l.split[2] if l.start_with? 'default' }
                  end
                end

                machine.communicate.execute('route -n', error_check: false) do |type, data|
                  if type == :stdout
                    data.each_line { |l| yield l.split[1] if l.start_with? '0.0.0.0' }
                  end
                end

                machine.communicate.execute('netstat -rn', error_check: false) do |type, data|
                  if type == :stdout
                    data.each_line { |l| yield l.split[1] if l.start_with? '0.0.0.0' }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
