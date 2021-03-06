require 'spec_helper'
require 'log_spy/spy'

describe LogSpy::Spy do
  let(:app) { double(:app) }
  let(:sqs_url) { 'the-sqs-url' }
  let(:options) { { :reigon => 'ap-southeast-1' } }

  describe '#new(app, sqs_url [, options = {}])' do
    it 'takes an app, an sqs_url, and an optional options to init' do
      LogSpy::Spy.new(app, sqs_url)
      LogSpy::Spy.new(app, sqs_url, options)
    end
  end

  describe '#call' do
    let(:sqs) { double(:sqs, :send_message => true) }
    # let(:sqs) { double(:sqs, :queues => double(:[] => queue)) }
    # let(:queue) { double(:queue, :send_message => true) }
    let(:call_result) { [200, { 'Content-Type' => 'application/json' }, [ 'body' ]] }
    let(:env) { {} }

    let(:request) { double(:request) }
    let(:payload) { double(:payload, :to_json => {'key' => 'val'}.to_json) }

    let(:middleware) { LogSpy::Spy.new(app, sqs_url, options) }
    let(:duration) { 20.12345 }
    let(:now) { Time.now }
    let(:three_sec_later) { now + duration }

    before :each do
      allow(Aws::SQS::Client).to receive_messages(:new => sqs)
      allow(app).to receive_messages(:call => call_result)
      allow(Rack::Request).to receive_messages(:new => request)
      allow(LogSpy::Payload).to receive_messages(:new => payload)
      allow(Time).to receive(:now).and_return(now, three_sec_later)
    end

    it 'creates a sqs client with options' do
      expect(Aws::SQS::Client).to receive(:new).with(options)

      middleware.call env
      middleware.sqs_thread.join
    end

    it 'creates payload with request, status, request_time' do
      expect(Rack::Request).to receive(:new).with(env)
      expect(LogSpy::Payload).to receive(:new) do |req, res, begin_at|
        expect(req).to be(request)
        expect(res.status).to eq(200)
        expect(begin_at).to eq(now.to_i)
        expect(res.duration).to eq((duration * 1000).round(0))
      end

      middleware.call env
      middleware.sqs_thread.join
    end

    it 'sends payload json to sqs with queue url' do
      expect(sqs).to receive(:send_message).with({
        queue_url: sqs_url,
        message_body: payload.to_json
      })
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
        expect(LogSpy::Payload).to receive(:new) do |req, res, begin_at, err|
          expect(req).to be(request)
          expect(res.status).to eq(500)
          expect(res.duration).to eq(( duration * 1000 ).round(0))
          expect(begin_at).to eq(now.to_i)
          expect(err).to eq(error)
        end

        begin
          middleware.call(env)
        rescue Exception
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
