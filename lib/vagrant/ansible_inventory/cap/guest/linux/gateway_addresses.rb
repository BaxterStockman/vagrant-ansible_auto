require 'set'

module VagrantPlugins
  module AnsibleInventory
    module Cap
      module Guest
        module Linux
          class GatewayAddresses
            class << self
              def gateway_addresses(machine)
                with_default_gateway_addresses(machine).to_a.compact
              end

            private

              def with_default_gateway_addresses(machine)
                return enum_for(__method__, machine) unless block_given?

                seen_addresses = Set.new
                yield_unseen_address = ->(a) do
                  yield a unless seen_addresses.include? a
                  seen_addresses << a
                end

                machine.communicate.execute('ip route show', error_check: false) do |type, data|
                  if type == :stdout
                    data.lines.each do |line|
                      if line.start_with?('default')
                        yield_unseen_address.call(line.split[2])
                      end
                    end
                  end
                end

                machine.communicate.execute('route -n', error_check: false) do |type, data|
                  if type == :stdout
                    data.lines.each do |line|
                      if line.start_with?('0.0.0.0')
                        yield_unseen_address.call(line.split[1])
                      end
                    end
                  end
                end

                machine.communicate.execute('netstat -rn', error_check: false) do |type, data|
                  if type == :stdout
                    data.lines.each do |line|
                      if line.start_with?('0.0.0.0')
                        yield_unseen_address.call(line.split[1])
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
  end
end
