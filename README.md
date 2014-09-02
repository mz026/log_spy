# LogSpy

LogSpy is a Rack middleware sending request log to [Amazon SQS](http://aws.amazon.com/sqs/).
After each request, `log_spy` opens a new thread and sends the request log payload as a `json` string onto [AWS SQS](http://aws.amazon.com/sqs/).

## Installation

Add this line to your application's Gemfile:

    gem 'log_spy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install log_spy

## Usage

require and use the middleware:

- bare rack:

```ruby
require 'log_spy'
use LogSpy::Spy, 'aws-sqs-url'
```

- rails:
```ruby
# application.rb
config.middleware.use LogSpy::Spy, 'aws-sqs-url', :reigon => 'ap-southeast-1'
```

## API Documents:

### to `use` the middleware:
- usage: `use LogSpy::Spy, <aws-sqs-url>[, <options>]`
- params:
  - `aws-sqs-url`(required): the [Queue URL](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/ImportantIdentifiers.html) of SQS, which identifies the queue.
  - `options`(optional): if given, `log_spy` would pass it to initialize [`AWS::SQS`](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SQS.html)

### the payload format sends to AWS SQS:

```json
{
  "path": "/the/request/path",
  "status": 200,
  "execution_time": 145.3, // in ms
  "request": {
    "path": "/the/request/path",
    "request_method": "post",
    "ip": "123.1.1.1",
    "query_string": "query-key=query-val&hello=world",
    "body": "body-key=body-val"
  },

  // if got exception
  "error": {
    "message": "the exception message",
    "backtrace": [ "exception back trace" ]
  }
}
```

- `error`: `error` would not be included in the payload if no exception was raised
- `request.body`: if the request `Content-Type` is of multipart, the body would be an empty string

## Testing:
`$ bundle install`
`$ bundle exec rspec spec/`


## Contributing

1. Fork it ( https://github.com/[my-github-username]/log_spy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
