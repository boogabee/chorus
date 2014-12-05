module Rails
  module Rack
    class Logger
      # This is a monkey-patch to the this file:
      #
      # /railties-3.2.9/lib/rails/rack/logger.rb
      #
      # All we did was change ip to remote_id
      #
      def started_request_message(request)
        'Started %s "%s" for %s at %s' % [
            request.request_method,
            request.filtered_path,
            request.remote_ip,
            Time.current.to_default_s ]
      end
    end
  end
end

module Kernel
  def pa(args)
    Rails.logger.debug(args)
    args
  end
end