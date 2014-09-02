require 'json'
class LogSpy::Payload
  def initialize req, res, error = nil
    @req = req
    @res = res
    @error = error
  end

  def to_json
    req_body = @req.content_type =~ /multipart/ ? '' : @req.body.read

    hash = {
      :path => @req.path,
      :status => @res.status,
      :execution_time => @res.duration,
      :request => {
        :content_type => @req.content_type,
        :request_method => @req.request_method,
        :ip => @req.ip,
        :query_string => @req.query_string,
        :body => req_body
      }
    }

    if @error
      hash[:error] = { :message => @error.message, :backtrace => @error.backtrace }
    end

    hash.to_json
  end
end
