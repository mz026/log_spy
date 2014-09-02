require 'spec_helper'
require 'log_spy/payload'

describe LogSpy::Payload do
  let(:path) { '/the/request/path' }
  let(:request_method) { 'post' }
  let(:ip) { '123.1.1.1' }
  let(:query_string) { 'query-key=query-val' }
  let(:status) { 200 }
  let(:duration) { 335 }
  let(:body) { double(:body, :read => 'the-raw-body') }
  let(:content_type) { 'application/json' }

  let(:request) do 
    double(:request,
           :path => path,
           :content_type => content_type,
           :request_method => request_method,
           :ip => ip,
           :query_string => query_string,
           :body => body)
  end

  let(:response) do
    double(:response,
           :status => status,
           :duration => duration)
  end

  let(:error) { Exception.new 'the-message' }

  describe '::new(request, response[, error = nil])' do
    it 'takes a request, response and an optional error to init' do
      payload = LogSpy::Payload.new request, response
      payload_with_err = LogSpy::Payload.new(request, response, error)
    end
  end

  describe '#to_json' do
    let(:expected_hash) do
      {
        :path => path,
        :status => status,
        :execution_time => duration,
        :request => {
          :content_type => content_type,
          :request_method => request_method,
          :ip => ip,
          :query_string => query_string,
          :body => body.read
        }
      }
    end

    context "if no error" do
      let(:payload) { LogSpy::Payload.new request, response }
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

    context "if with error" do
      let(:payload) { LogSpy::Payload.new request, response, error }
      it 'returns error with message and backtrace' do
        expected_hash[:error] = {
          :message => error.message,
          :backtrace => error.backtrace
        }

        expect(payload.to_json).to eq(expected_hash.to_json) 
      end
      
    end
  end
end
