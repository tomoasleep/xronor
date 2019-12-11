module Xronor
  class DSL
    class Job
      include Xronor::DSL::Checker

      class << self
        def define_metadata(name)
          fail "Cannot use #{name} for metadata" if %i(description name schedule command).include?(name.to_sym)
          define_method(name) do |value|
            @result.public_send("#{name}=", value)
          end
        end
      end

      def initialize(frequency, options, &block)
        @frequency = frequency
        @options = options

        schedule = case frequency
                   when String # cron expression
                     frequency
                   when Symbol, Numeric # DSL (:hour, 1.min, 1.hour, ...)
                     Xronor::DSL::ScheduleConverter.convert(frequency, options)
                   else
                     raise ArgumentError, "Invalid frequency #{frequency}"
                   end

        @result = OpenStruct.new(
          description: nil,
          name: "",
          schedule: schedule,
          command: "",
        )

        instance_eval(&block)
      end

      %i(description name).each do |key|
        define_method(key) do |arg|
          @result.send("#{key}=", arg)
        end
      end

      def process_template(template, options)
        template.gsub(/:\w+/) do |key|
          before_and_after = [$`[-1..-1], $'[0..0]]
          option = options[key.sub(':', '').to_sym] || key

          if before_and_after.all? { |c| c == "'" }
            escape_single_quotes(option)
          elsif before_and_after.all? { |c| c == '"' }
            escape_double_quotes(option)
          else
            option
          end
        end.gsub(/\s+/m, " ").strip
      end

      def result
        required(:name, @result.name)
        @result
      end

      private

      def escape_single_quotes(str)
        str.gsub(/'/) { "'\\''" }
      end

      def escape_double_quotes(str)
        str.gsub(/"/) { '\"' }
      end
    end
  end
end
