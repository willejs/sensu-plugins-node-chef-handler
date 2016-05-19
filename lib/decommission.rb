require 'rubygems'
require 'chef'
require 'aws'
require 'sensu-handler'

module Sensu::Extension
  # decommission nodes in sensu
  class DecommissionHandler < Sensu::Handler
    def name
      definition[:name]
    end

    def definition
      {
        type: 'extension',
        name: 'decommission-handler'
      }
    end

    def description
      'Handles node failures and cleans them up in chef and sensu'
    end

    # Called when Sensu begins to shutdown.
    def stop
      true
    end

    def run(event_data)
      event = parse_event(event_data)
      puts 'Decommission handler handling event'
      if event['check']['name'] == 'keepalive' && event['action'] == 'create'
        puts 'check name is keepalive'
        if !ec2_instance_is_healthy?(event)
          delete_from_chef(event)
          delete_sensu_client(event)
          yield("Decommissioned node: #{event['client']['name']}")
        else
          yield('No action. node status is healthy', 0)
        end
      else
        yield('check is not a keepalive', 0)
      end
    end

    # private

    def parse_event(event_data)
      begin
        JSON.parse(event_data)
      rescue
        yield('Failed to parse event data', 1)
      end
    end

    def delete_from_chef(event)
      Chef::Config.from_file('/etc/chef/client.rb')
      begin
        puts 'loading chef client'
        node = Chef::Node.load(event['client']['name'])
        puts node.inspect
        node.destroy
      rescue Net::HTTPServerException => e
        if e == '404 "Object Not Found"'
          puts 'chef node doesent exist'
        else
          puts e
        end
      end

      begin
        client = Chef::ApiClient.load(event['client']['name'])
        client.destroy
      rescue Net::HTTPServerException => e
        if e == '404 "Object Not Found"'
          puts 'chef client doesent exist'
        else
          puts e
        end
      end
    end

    def delete_sensu_client(event)
      puts "Sensu client #{event['client']['name']} is being deleted."
      result = api_request(:DELETE, "/clients/#{event['client']['name']}").code == '202'
      case result
      when '202'
        puts 'deleted client from sensu'
      else
        puts "Sensu API call failed. HTTP Code: #{result}"
      end
    end

    def ec2_instance_is_healthy?(event)
      # if you get authentication errors, you need to use IAM roles
      ec2 = AWS::EC2.new(
        ec2_endpoint: "ec2.#{event['client']['region']}.amazonaws.com"
      )
      begin
        instance = ec2.instances[event['client']['instance_id']]
      rescue => e
        puts e
      end

      if instance.exists?
        puts "Instance #{event['client']['name']} exists; Checking state"
        if instance.status.to_s == 'terminated' || instance.status.to_s == 'shutting_down'
          puts "Instance: #{event['client']['name']} is state: #{instance.status}"
          false
        else
          puts "Instance: #{event['client']['name']} is state: #{instance.status}"
          true
        end
      end
    end
  end
end
