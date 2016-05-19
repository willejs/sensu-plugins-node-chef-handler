require 'sensu/extension'
require 'sensu-handler'
require 'json'
require 'webmock/rspec'

require_relative '../lib/decommission.rb'

describe 'Sensu::Extension::DecommissionHandler' do
  before do
    @extension = Sensu::Extension::DecommissionHandler.new
    allow(@extension).to receive(:ec2_instance_is_healthy?).and_return(true)
    allow(@extension).to receive(:delete_from_chef).and_return(nil)
    stub_request(:any, 'www.example.com')
    http_object = Net::HTTP.get_response(URI.parse('http://www.example.com/'))
    allow(@extension).to receive(:api_request).and_return(http_object)
    @event = JSON.parse('{
      "id": "2f6c6e64-9b46-42b6-9c27-3a746c4aaeb9",
      "client": {
        "name": "i-ecs-i-7199d2c1",
        "instance_id": "i-7199d2c1",
        "region": "us-east-1"
      },
      "check": {
        "name": "keepalive"
      },
      "occurrences": 1,
      "action": "create"
    }')
  end

  it 'can run' do
    @extension.run(@event.to_json) do |output, status|
      puts status
      puts output
    end
  end

  it 'can delete from chef' do
    @event['client']['name'] = 'test'
    @extension.delete_from_chef(@event) do |output, status|
      puts status
      puts output
    end
  end

  it 'can delete from sensu' do
    @event['client']['name'] = 'test'
    @extension.delete_sensu_client(@event) do |output, status|
      puts status
      puts output
    end
  end
end
