# frozen_string_literal: true

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          class PrivateKey
            class << self
              def generate_private_key(machine, path, type = 'rsa', bits = '2048')
                return unless machine.guest.capability?(:executable_installed?) \
                  && machine.guest.capability(:executable_installed?, 'ssh-keygen')

                machine.communicate.execute("ssh-keygen -t #{type} -b #{bits} -C 'Vagrant-generated keypair' -f #{path}")
              end
            end
          end
        end
      end
    end
  end
end
