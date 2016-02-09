# LogSpy

LogSpy is a Rack middleware sending request log to [Amazon SQS](http://aws.amazon.com/sqs/) on each request.

## How it works

After each request, `log_spy` opens a new thread and sends the request log payload as a `json` string onto [AWS SQS](http://aws.amazon.com/sqs/).

## Why not use Papertrail or other log collector?

Logspy does not intend to replace the log collectors like Papertrail or something similar.
The purpose of Logspy is to record each request and its params so that we can easily analyse even replay requests within a certain period.

## Installation

Add this line to your application's Gemfile:

    gem 'log_spy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install log_spy

## Usage

require and use the middleware:

- Bare Rack:

```ruby
require 'log_spy'
use LogSpy::Spy, 'aws-sqs-url'
```

- Rails:
```ruby
# config/application.rb
config.middleware.use LogSpy::Spy, 'aws-sqs-url', :reigon => 'ap-southeast-1',
                                                  :access_key_id => 'the-key-id',
                                                  :secret_access_key => 'the-secret'
```

## API Documents:

### to `use` the middleware:
- usage: `use LogSpy::Spy, <aws-sqs-url>[, <options>]`
- params:
  - `aws-sqs-url`(required): the [Queue URL](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/ImportantIdentifiers.html) of SQS, which identifies the queue.
  - `options`(optional): if given, `log_spy` would pass it to initialize [`Aws::SQS`](http://docs.aws.amazon.com/sdkforruby/api/Aws/SQS.html)

### the payload format sends to AWS SQS:

```javascript
{
  "path": "/the/request/path",
  "status": 200,
  "execution_time": 145.3, // in ms
  "controller_action": "users#show", // if env['action_dispatch.request.parameters'] exists
  "request": {
    "content_type": "application/json",
    "request_method": "post",
    "ip": "123.1.1.1",
    "query_string": "query-key=query-val&hello=world",
    "body": "body-key=body-val",
    "cookies": {
      "cookie_key": "cookie_val"
    }
  },

  // if got exception
  "error": {
    "message": "the exception message",
    "backtrace": [ "exception back trace" ]
  }
}
```

- `error`: `error` would not be included in the payload if no exception was raised
- `request.body`: if the request `Content-Type` is of `multipart`, the body would be an empty string

## Testing:
`$ bundle install`
`$ bundle exec rspec spec/`


## Contributing

1. Fork it ( https://github.com/[my-github-username]/log_spy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
