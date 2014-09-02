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

    let(:request) { double(:request) }
    let(:payload) { double(:payload, :to_json => {'key' => 'val'}.to_json) }

    let(:middleware) { LogSpy::Spy.new(app, sqs_url, options) }
    let(:duration) { 20 }
    let(:now) { Time.now }
    let(:three_sec_later) { now + duration }

    before :each do
      allow(AWS::SQS).to receive_messages(:new => sqs)
      allow(app).to receive_messages(:call => call_result)
      allow(Rack::Request).to receive_messages(:new => request)
      allow(LogSpy::Payload).to receive_messages(:new => payload)
      allow(Time).to receive(:now).and_return(now, three_sec_later)
    end

    it 'config sqs with options' do
      expect(AWS::SQS).to receive(:new).with(options)

      middleware.call env
      middleware.sqs_thread.join
    end

    it 'sends payload json json to sqs' do
      expect(Rack::Request).to receive(:new).with(env)

      expect(queue).to receive(:send_message).with(payload.to_json)
      middleware.call env
      middleware.sqs_thread.join
    end

    it 'builds payload with request, status, request_time' do
      expect(LogSpy::Payload).to receive(:new) do |req, res|
        expect(req).to be(request)
        expect(res.status).to eq(200)
        expect(res.duration).to eq(duration)
      end

      middleware.call env
      middleware.sqs_thread.join
    end

    it 'returns original result' do
      expect(middleware.call(env)).to eq(call_result)
      middleware.sqs_thread.join
    end

    context "if `app.call raises`" do
      let(:error) { Exception.new }

      before :each do
        allow(app).to receive(:call).and_raise(error)
      end
      
      it 'build payload with error' do
        expect(LogSpy::Payload).to receive(:new) do |req, res, err|
          expect(req).to be(request)
          expect(res.status).to eq(500)
          expect(res.duration).to eq(duration)
          expect(err).to eq(error)
        end

        begin
          middleware.call(env)
        rescue Exception => e
        end

        middleware.sqs_thread.join
      end

      it 'forward to error' do
        expect {
          middleware.call(env)
        }.to raise_error(error)

        middleware.sqs_thread.join
      end
    end
    
  end
end
