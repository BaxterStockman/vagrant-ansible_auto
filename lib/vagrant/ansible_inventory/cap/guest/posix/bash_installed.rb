module VagrantPlugins
  module AnsibleInventory
    module Cap
      module Guest
        module POSIX
          class BashInstalled
            class << self
              def bash_installed?(machine, version=nil)
                machine.communicate.execute(%q[command bash -c 'printf -- "%s\t%s" "$BASH" "$BASH_VERSION"'], error_check: false) do |type, data|
                  data.chomp!

                  # Not sure why, but we always get an empty first line...
                  next if data.empty?

                  if type == :stdout
                    bash_path, bash_version = *(data.split("\t"))
                    return ((!bash_path.empty?) and (version.nil? or version == bash_version))
                  end
                end

                false
              end
            end
          end
        end
      end
    end
  end
end
