require 'set'

module VagrantPlugins
  module AnsibleInventory
    module Cap
      module Guest
        module Linux
          class SSHServerAddress
            class << self
              def ssh_server_address(machine, target_machine=nil)
                with_open_ports(machine, target_machine).first
              end

            private

              def ssh_server_addresses(machine, target_machine=nil)
                with_open_ports(machine, target_machine).to_a
              end

              def with_open_ports(machine, target_machine=nil)
                return enum_for(__method__, machine, target_machine) unless block_given?

                return unless machine.guest.capability?(:check_open_port)

                target_machine ||= machine

                with_candidate_addresses(target_machine) do |host, port|
                  port ||= target_machine.ssh_info[:port]

                  if machine.guest.capability(:check_open_port, host, port)
                    yield host, port
                  end
                end
              end

              network_type_precedence_map = Hash[[:forwarded_port, :public_network, :private_network].each_with_index.map { |type, i| [type, i] }]
              define_method(:network_type_precedence) do |type|
                network_type_precedence_map[type]
              end

              def with_candidate_addresses(machine)
                return enum_for(__method__, machine) unless block_given?

                seen_candidates = Set.new
                yield_unseen_candidate = ->(host_and_port) do
                  yield(*host_and_port) unless seen_candidates.include?(host_and_port)
                  seen_candidates << host_and_port
                end

                if machine.provider.capability?(:public_address)
                  yield_unseen_candidate.call([machine.provider.capability(:public_address)])
                end

                unless machine.ssh_info.nil?
                  yield_unseen_candidate.call([machine.ssh_info[:host]])
                end

                has_routable_ip = false
                machine.config.vm.networks.sort_by do |(type, _)|
                  network_type_precedence(type)
                end.each do |(type, info)|
                  case type
                    when :private_network, :public_network
                      has_routable_ip = true

                      if info.key?(:ip)
                        yield_unseen_candidate.call([info[:ip]])
                      end
                    when :forwarded_port
                      # TODO the `:id' restriction might not be right.
                      if info[:protocol] == 'tcp' and info[:id] == 'ssh'
                        yield_unseen_candidate.call([info[:host_ip], info[:host]])
                      end
                  end
                end

                if !has_routable_ip and machine.guest.capability?(:gateway_addresses)
                  machine.guest.capability(:gateway_addresses).each do |gateway_address|
                    yield_unseen_candidate.call(gateway_address)
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
