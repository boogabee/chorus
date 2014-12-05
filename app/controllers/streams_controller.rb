class StreamsController < ApplicationController
  include FileDownloadHelper

  private

  def stream(dataset, user, options = {})
    streamer_options = convert_params(options.symbolize_keys)
    @streamer = SqlStreamer.new(
        dataset.all_rows_sql(streamer_options[:row_limit]),
        dataset.connect_as(user),
        streamer_options
    )

    filename = filename_for_download(dataset.name)
    response.headers["Content-Disposition"] = "attachment; filename=\"#{filename}.csv\""
    response.headers["Cache-Control"] = 'no-cache'
    response.headers["Transfer-Encoding"] = 'chunked'

    begin
      self.response_body = @streamer.enum
    rescue ActiveRecord::RecordNotFound => e
      self.response_body = e.message
    end
  end

  def convert_params(streamer_options)
    streamer_options[:row_limit] = streamer_options[:row_limit].to_i if streamer_options[:row_limit].to_i > 0
    if streamer_options[:header]
      streamer_options[:header] = streamer_options[:header] == 'false' ? false : true
    end

    streamer_options
  end
end
