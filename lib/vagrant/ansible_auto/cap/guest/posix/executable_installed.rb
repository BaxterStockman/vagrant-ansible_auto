# frozen_string_literal: true

require 'vagrant/ansible_auto/util/shell_quote'

module VagrantPlugins
  module AnsibleAuto
    module Cap
      module Guest
        module POSIX
          # Check whether an executable is installed
          class ExecutableInstalled
            extend Util::ShellQuote

            class << self
              # @param [Machine] machine a guest machine
              # @param [#to_s] executable name or path of an executable
              # @return [Boolean] whether the executable exists and has the
              #   executable bit set
              def executable_installed?(machine, executable)
                machine.communicate.test(%[test -x "$(command -v '#{shellescape(executable)}')"], error_check: false)
              end
            end
          end
        end
      end
    end
  end
end
