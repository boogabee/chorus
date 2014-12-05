class DatasetDownloadsController < StreamsController
  include DataSourceAuth

  def show
    dataset = Dataset.find(params[:dataset_id])
    stream_options = params.slice(:row_limit, :header)
    stream(dataset, current_user, stream_options.merge({:quiet_null => true, :rescue_connection_errors => true}))
  end
end
