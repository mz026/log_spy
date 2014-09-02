require 'spec_helper'
require 'log_spy/spy'

describe LogSpy::Spy do
  let(:app) { double(:app) }
  let(:sqs_url) { 'the-sqs-url' }
  let(:options) { { :reigon => 'ap-southeast-1' } }

  describe '#new(app, sqs_url [, options = {}])' do
    it 'takes an app, an sqs_url, and an optional options to init' do
      middleware = LogSpy::Spy.new(app, sqs_url)
      middleware_w_options = LogSpy::Spy.new(app, sqs_url, options)
    end
  end

  describe 'call' do
    let(:sqs) { double(:sqs, :queues => double(:[] => queue)) }
    let(:queue) { double(:queue, :send_message => true) }
    let(:call_result) { [200, { 'Content-Type' => 'application/json' }, [ 'body' ]] }
    let(:env) { {} }

    let(:middleware) { LogSpy::Spy.new(app, sqs_url, options) }

    before :each do
      allow(AWS::SQS).to receive_messages(:new => sqs)
      allow(app).to receive_messages(:call => call_result)
    end

    it 'config sqs with options' do
      expect(AWS::SQS).to receive(:new).with(options)

      middleware.call env
    end

    it 'sends log object json to sqs' do
      request = double(:request)
      expect(Rack::Request).to receive(:new).with(env).and_return(request)

      payload = double(:payload, :to_json => { 'key' => 'val' }.to_json)
      expect(LogSpy::Payload).to receive(:new).with(request).and_return(payload)

      expect(queue).to receive(:send_message).with(payload.to_json)
      middleware.call env
    end


    
  end
end
