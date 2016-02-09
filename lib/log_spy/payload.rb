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
        :cookies => @req.cookies,
        :body => request_body
      }
    }

    append_error_if_exists(hash)
    append_controller_action_if_exists(hash)

    hash.to_json
  end

  def append_error_if_exists hash
    if @error
      hash[:error] = { :message => @error.message, :backtrace => @error.backtrace }
    end
  end
  private :append_error_if_exists

  def append_controller_action_if_exists hash
    if controller_params = @req.env['action_dispatch.request.parameters']
      hash[:controller_action] = "#{controller_params['controller']}##{controller_params['action']}"
    end
  end
  private :append_controller_action_if_exists

  def request_body
    return '' if @req.content_type =~ /multipart/
    @req.body.rewind
    @req.body.read
  rescue IOError
    @req.env['RAW_POST_BODY']
  end
  private :request_body
end
