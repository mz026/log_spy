require 'aws-sdk'
require 'rack'
require 'log_spy/payload'
require 'json'

class LogSpy::Spy
  def initialize(app, sqs_url, options = {})
    @app = app
    @sqs_url = sqs_url
    @options = options
  end

  def call env
    sqs = AWS::SQS.new(@options)
    req = Rack::Request.new env
    payload = ::LogSpy::Payload.new(req)

    sqs.queues[@sqs_url].send_message(payload.to_json)
  end
end
