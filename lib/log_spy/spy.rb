require 'aws-sdk'
require 'rack'
require 'log_spy/payload'
require 'json'
require 'ostruct'

class LogSpy::Spy
  attr_reader :sqs_thread
  def initialize(app, sqs_url, options = {})
    @app = app
    @sqs_url = sqs_url
    @options = options
  end

  def call env
    start_time = Time.now.to_i
    req = Rack::Request.new env
    status, header, body = @app.call(env)
    duration = Time.now.to_i - start_time

    @sqs_thread = Thread.new do
      sqs = AWS::SQS.new(@options)
      res = OpenStruct.new({
        :duration => duration,
        :status => status
      })
      payload = ::LogSpy::Payload.new(req, res)

      sqs.queues[@sqs_url].send_message(payload.to_json)
    end

    [ status, header, body ]

  rescue Exception => err
    duration = Time.now.to_i - start_time
    @sqs_thread = Thread.new do
      sqs = AWS::SQS.new(@options)
      res = OpenStruct.new({
        :duration => duration,
        :status => 500 
      })
      payload = ::LogSpy::Payload.new(req, res, err)

      sqs.queues[@sqs_url].send_message(payload.to_json)
    end

    raise err
  end
end
