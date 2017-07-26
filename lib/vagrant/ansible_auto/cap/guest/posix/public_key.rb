# frozen_string_literal: true

require 'vagrant/ansible_auto/util/shell_quote'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          class PrivateKey
            class << self
              def fetch_public_key(machine, path)
                return unless machine.guest.capability?(:executable_installed?) \
                  && machine.guest.capability(:executable_installed?, 'ssh-keygen')

                # TODO: handle bad status
                public_key = ''
                _status = machine.communicate.execute("ssh-keygen -f #{path} -y") do |data_type, data|
                  public_key += data if data_type == :stdout
                end

                public_key
              end

              def authorized_key?(machine, content, path = '~/.ssh/authorized_keys')
                machine.communicate.test("grep -q -x -F '#{shellescape(content.chomp)}' #{shellescape(path)}")
              end
            end
          end
        end
      end
    end
  end
end
