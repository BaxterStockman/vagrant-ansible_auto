# frozen_string_literal: true

require 'vagrant/ansible_auto/util/shell_quote'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          # Create a private key
          class PrivateKey
            extend Util::ShellQuote

            class << self
              # @param [Vagrant::Machine] machine a guest machine
              # @param [#to_s] path the output path for the generated private
              #   key
              # @param [String] type the type of key to generate. Takes any
              #   valid type to the +ssh-keygen+ utility's +-t+ option
              # @param [String] bits the bits of entropy.  Takes any value
              #   valid for the +ssh-keygen+ utility's +-b+ option
              # @return [nil] if +ssh-keygen+ is not available on the machine
              # @todo document return value!
              def generate_private_key(machine, path, type = 'rsa', bits = '2048')
                return unless machine.guest.capability?(:executable_installed?) \
                  && machine.guest.capability(:executable_installed?, 'ssh-keygen')

                cmd = "ssh-keygen -t #{shellescape(type)} -b #{shellescape(bits)} -C 'Vagrant-generated keypair' -f #{shellescape(path)}"
                machine.communicate.execute(cmd)
              end
            end
          end
        end
      end
    end
  end
end
