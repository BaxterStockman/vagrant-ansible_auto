# frozen_string_literal: true

require 'set'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          # Attempt to find the IP address and port of an active SSH server
          # @todo test not merely that a host and port combo is open, but that
          #   there's an SSH server listening there
          class SSHServerAddress
            class << self
              # @param [Vagrant::Machine] machine a guest machine
              # @param [Vagrant::Machine,nil] target_machine a guest machine
              # @return [Array<(String, Integer)>] the host and port on which
              #   an SSH server may be listening
              def ssh_server_address(machine, target_machine = nil)
                with_open_ports(machine, target_machine).first
              end

              # @param (see #ssh_server_address)
              # @return [Array<Array<(String, Integer)>>] a list of host and
              #   port pairs on which an SSH server may be listening
              def ssh_server_addresses(machine, target_machine = nil)
                with_open_ports(machine, target_machine).to_a
              end

            private

              def with_open_ports(machine, target_machine = nil)
                return enum_for(__method__, machine, target_machine) unless block_given?

                return unless machine.guest.capability?(:port_open?)

                target_machine ||= machine
                ssh_info = target_machine.ssh_info
                default_port = ssh_info.nil? ? 22 : ssh_info[:port]

                with_candidate_addresses(target_machine) do |host, port|
                  port ||= default_port

                  if machine.guest.capability(:port_open?, host, port)
                    yield host, port
                  end
                end
              end

              network_type_precedence_map = Hash[%i[forwarded_port public_network private_network].each_with_index.map { |type, i| [type, i] }]
              define_method(:network_type_precedence) do |type|
                network_type_precedence_map[type]
              end

              def with_candidate_addresses(machine)
                return enum_for(__method__, machine) unless block_given?

                seen_candidates = Set.new
                yield_unseen_candidate = lambda do |host_and_port|
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
                machine.config.vm.networks.sort_by { |(type, _)| network_type_precedence(type) }.each do |type, info|
                  case type
                  when :private_network, :public_network
                    has_routable_ip = true

                    yield_unseen_candidate.call([info[:ip]]) if info.key?(:ip)
                  when :forwarded_port
                    # TODO: the `:id' restriction might not be right.
                    if info[:protocol] == 'tcp' && info[:id] == 'ssh'
                      yield_unseen_candidate.call([info[:host_ip], info[:host]])
                    end
                  end
                end

                return if has_routable_ip || !machine.guest.capability?(:gateway_addresses)

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
