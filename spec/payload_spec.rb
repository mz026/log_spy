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
  # let(:body) { double(:body, :read => 'the-raw-body') }
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

    context "if request ends without error" do
      let(:payload) { LogSpy::Payload.new request, response, begin_at }

      context "if body can be read" do
        before(:each) { 
          allow(body).to receive_messages(:read => 'the-raw-body') 
          expected_hash[:request][:body] = 'the-raw-body'
        }

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

      context "if body can not be read" do
        before(:each) do
          allow(body).to receive(:read).and_raise(Exception, 'closed stream')
          allow(request).to receive_messages(:env => { 'RAW_POST_BODY' => 'raw-post-body' })
          expected_hash[:request][:body] = 'raw-post-body'
        end

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

    end

    context "if request ends with error" do
      let(:payload) { LogSpy::Payload.new request, response, begin_at, error }
      before :each do
        expected_hash[:error] = {
          :message => error.message,
          :backtrace => error.backtrace
        }
      end

      context "if request body can be read" do
        before(:each) { 
          allow(body).to receive_messages(:read => 'the-raw-body') 
          expected_hash[:request][:body] = 'the-raw-body'
        }
        
        it 'returns error with message and backtrace' do
          expect(payload.to_json).to eq(expected_hash.to_json) 
        end
      end

      context "if request body can not be read" do
        before(:each) do
          allow(body).to receive(:read).and_raise(Exception, 'closed stream')
          allow(request).to receive_messages(:env => { 'RAW_POST_BODY' => 'raw-post-body' })
          expected_hash[:request][:body] = 'raw-post-body'
        end

        it 'returns error with message and backtrace' do
          expect(payload.to_json).to eq(expected_hash.to_json) 
        end

        it 'returns no body if request content_type is multipart' do
          allow(request).to receive_messages(:content_type => 'multipart/form-data')
          expected_hash[:request][:content_type] = 'multipart/form-data'
          expected_hash[:request][:body] = ''
          expect(payload.to_json).to eq(expected_hash.to_json) 
        end
      end
    end
  end
end
