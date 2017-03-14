module Wh2cwe
  module AWS
    class CloudWatchEvents
      def initialize(client: Aws::CloudWatchEvents::Client.new)
        @client = client
      end

      def register_job(name, cron, cluster, task_definition, container, command, target_function_arn)
        rule_arn = put_rule(name, cron)
        put_target(name, cluster, task_definition, container, command, target_function_arn)
        rule_arn
      end

      private

      def put_rule(name, cron)
        @client.put_rule({
          name: name,
          schedule_expression: cron,
        }).rule_arn
      end

      def put_target(name, cluster, task_definition, container, command, target_function_arn)
        @client.put_targets({
          rule: name,
          targets: [
            {
              id: generate_id,
              arn: target_function_arn,
              input_transformer: {
                input_paths_map: {
                  "resources" => "$.resources",
                  "time" => "$.time",
                },
                input_template: generate_input_template(cluster, task_definition, container, command),
              },
            },
          ],
        })
      end

      def generate_input_template(cluster, task_definition, container, command)
        JSON.generate({
          "resources" => '###$.resources###',
          "time" => '###$.time###',
          "cluster" => cluster,
          "task_definition" => task_definition,
          "container" => container,
          "command" => Shellwords.split(command),
        }).sub('"###$.resources###"', "<reosurces>").sub('"###$.time###"', "<time>")
      end

      def generate_id
        SecureRandom.uuid
      end
    end
  end
end