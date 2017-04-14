# frozen_string_literal: true
require 'uri'

module VagrantPlugins
  module AnsibleInventory
    module Cap
      module Guest
        module POSIX
          class CheckOpenPort
            class << self
              def check_open_port(machine, host, port, proto = 'tcp')
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

                target = File.join('/dev/', proto, uri.host, uri.port.to_s).shellescape
                machine.communicate.test("read < #{target}", shell: '/bin/bash')
              end
            end
          end
        end
      end
    end
  end
end
