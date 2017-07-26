# frozen_string_literal: true

require 'vagrant/ansible_auto/util/shell_quote'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          # Grab a public key from a guest machine
          class PublicKey
            extend Util::ShellQuote

            class << self
              # @param [Vagrant::Machine] machine a guest machine
              # @param [#to_s] path path to the public key
              # @return [nil] if the public key file cannot be read
              # @return [String if the public key file can be read, its
              #   contents
              def fetch_public_key(machine, path)
                return unless machine.guest.capability?(:executable_installed?) \
                  && machine.guest.capability(:executable_installed?, 'ssh-keygen')

                # TODO: handle bad status
                public_key = ''
                machine.communicate.execute("ssh-keygen -f #{shellescape(path)} -y") do |data_type, data|
                  public_key += data if data_type == :stdout
                end

                return if public_key.empty?

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
