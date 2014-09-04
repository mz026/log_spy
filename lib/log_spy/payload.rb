require 'json'
class LogSpy::Payload
  def initialize req, res, begin_at, error = nil
    @req = req
    @res = res
    @error = error
    @begin_at = begin_at
  end

  def to_json
    hash = {
      :path => @req.path,
      :status => @res.status,
      :execution_time => @res.duration,
      :begin_at => @begin_at,
      :request => {
        :content_type => @req.content_type,
        :request_method => @req.request_method,
        :ip => @req.ip,
        :query_string => @req.query_string,
        :body => request_body
      }
    }

    if @error
      hash[:error] = { :message => @error.message, :backtrace => @error.backtrace }
    end

    hash.to_json
  end

  def request_body
    return '' if @req.content_type =~ /multipart/
    @req.body.read
  rescue Exception => e
    @req.env['RAW_POST_BODY']
  end
end
