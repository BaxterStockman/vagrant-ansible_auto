require 'vagrant'

module YARD
  module VagrantPlugins
    # Custom class handler for documenting class inheritance from
    # +Vagrant.plugin+
    class ClassHandler < YARD::Handlers::Ruby::ClassHandler
    private

      def parse_superclass(superclass)
        return nil unless superclass

        case superclass.type
        when :call, :command_call
          cname = superclass.namespace.source
          if cname =~ /^Vagrant$/ && superclass.method_name(true) == :plugin
            members = superclass.parameters.map { |m| handle_superclass_parameter(m) }

            begin
              return Vagrant.plugin(*(members[0..1])).to_s
            end
          end
        end

        super
      end

      def handle_superclass_parameter(parameter)
        case parameter
        when TrueClass, FalseClass, NilClass
          parameter
        else
          case parameter.type
          when :symbol_literal
            parameter.source[1..-1].to_sym
          when :int
            parameter.source.to_i
          else
            parameter.source
          end
        end
      end
    end
  end
end
