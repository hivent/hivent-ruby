# frozen_string_literal: true
module Hivent

  module Config

    module Options

      class UnsupportedOptionError < StandardError; end

      def defaults
        @defaults ||= {}
      end

      def validators
        @validators ||= {}
      end

      def option(name, options = {})
        defaults[name] = settings[name] = options[:default]
        validators[name] = options[:validate] || ->(_value) { true }

        class_eval <<-RUBY
          def #{name}
            settings[#{name.inspect}]
          end
          def #{name}=(value)
            unless validators[#{name.inspect.to_sym}].(value)
              raise UnsupportedOptionError.new("Unsupported value " + value.inspect + " for option #{name.inspect}")
            end

            settings[#{name.inspect}] = value
          end
          def #{name}?
            #{name}
          end

          def reset_#{name}
            settings[#{name.inspect}] = defaults[#{name.inspect}]
          end
        RUBY
      end

      def settings
        @settings ||= {}
      end

    end

  end

end
