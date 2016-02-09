require 'spec_helper'
require 'log_spy/payload'

describe LogSpy::Payload do
  let(:path) { '/the/request/path' }
  let(:request_method) { 'post' }
  let(:ip) { '123.1.1.1' }
  let(:query_string) { 'query-key=query-val' }
  let(:status) { 200 }
  let(:duration) { 335 }
  let(:body) { double(:body) }
  let(:content_type) { 'application/json' }

  before :each do
    allow(body).to receive_messages(:rewind => body)
  end

  let(:request) do
    double(:request,
           :path => path,
           :content_type => content_type,
           :request_method => request_method,
           :ip => ip,
           :query_string => query_string,
           :env => {},
           :body => body)
  end

  let(:response) do
    double(:response,
           :status => status,
           :duration => duration)
  end

  let(:error) { Exception.new 'the-message' }
  let(:begin_at) { Time.now.to_i }

  describe '::new(request, response, begin_at[, error = nil])' do
    it 'takes a request, response and an optional error to init' do
      payload = LogSpy::Payload.new(request, response, begin_at)
      payload_with_err = LogSpy::Payload.new(request, response, begin_at, error)
    end
  end

  describe '#to_json' do
    let(:expected_hash) do
      {
        :path => path,
        :status => status,
        :execution_time => duration,
        :begin_at => begin_at,
        :request => {
          :content_type => content_type,
          :request_method => request_method,
          :ip => ip,
          :query_string => query_string
        }
      }
    end

    shared_examples 'ensure_payload_formats' do
      it 'returns correct format' do
        expect(payload.to_json).to eq(expected_hash.to_json)
      end

      it 'returns no body if request content_type is multipart' do
        allow(request).to receive_messages(:content_type => 'multipart/form-data')
        expected_hash[:request][:content_type] = 'multipart/form-data'
        expected_hash[:request][:body] = ''
        expect(payload.to_json).to eq(expected_hash.to_json)
      end
    end

    shared_context "if_body_readable" do
      before(:each) do
        allow(body).to receive_messages(:rewind => 0)
        allow(body).to receive_messages(:read => 'the-raw-body')
        expected_hash[:request][:body] = 'the-raw-body'
      end
    end

    shared_context 'if_body_unreadable' do
      before(:each) do
        allow(body).to receive(:rewind).and_raise(IOError, 'closed stream')
        allow(request).to receive_messages(:env => { 'RAW_POST_BODY' => 'raw-post-body' })
        expected_hash[:request][:body] = 'raw-post-body'
      end

    end

    shared_examples "ensure_action_dispatch_controller_params" do
      before :each do
        controller_params = { 'controller' => 'users', 'action' => 'show' }
        env = { 'action_dispatch.request.parameters' => controller_params }
        allow(request).to receive_messages(:env => env)
      end

      it 'returns hash with `controller_action`' do
        expected_hash[:controller_action] = "users#show"

        expect(payload.to_json).to eq(expected_hash.to_json)
      end
    end

    context "if request ends without error" do
      let(:payload) { LogSpy::Payload.new request, response, begin_at }

      context "if env['action_dispatch.request.parameters']" do
        include_context "if_body_readable"
        include_examples "ensure_action_dispatch_controller_params"
      end

      context "if body can be read" do
        include_context "if_body_readable"
        include_examples 'ensure_payload_formats'
      end

      context "if body can not be read" do
        include_context "if_body_unreadable"
        include_examples 'ensure_payload_formats'
      end

    end

    context "if request ends with error" do
      let(:payload) { LogSpy::Payload.new request, response, begin_at, error }
      before :each do
        expected_hash[:error] = {
          :message => error.message,
          :backtrace => error.backtrace
        }
      end

      context "if env['action_dispatch.request.parameters']" do
        include_context "if_body_readable"
        include_examples "ensure_action_dispatch_controller_params"
      end

      context "if request body can be read" do
        include_context 'if_body_readable'
        include_examples 'ensure_payload_formats'
      end

      context "if request body can not be read" do
        include_context 'if_body_unreadable'
        include_examples 'ensure_payload_formats'
      end
    end
  end
end
