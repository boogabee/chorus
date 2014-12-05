class PreviewsController < ApplicationController
  include DataSourceAuth

  wrap_parameters :task, :exclude => [:id, :dataset_id]

  def create
    dataset = Dataset.find(params[:dataset_id])
    authorize_data_source_access(dataset)

    check_id = params[:task][:check_id]
    query = CancelableQuery.new(dataset.connect_as(current_user), check_id, current_user)
    result = query.execute(dataset.preview_sql, :limit => ChorusConfig.instance['default_preview_row_limit'])
    present(result, :status => :created)
  end 

  def destroy
    dataset = Dataset.find(params[:dataset_id])
    authorize_data_source_access(dataset)

    CancelableQuery.cancel(params[:id], current_user)
    head :ok
  end

  def preview_sql
    task = params[:task]
    schema = GpdbSchema.find(task[:schema_id])
    authorize_data_source_access(schema)

    sql_without_semicolon = task[:query].gsub(';', '')
    sql = "SELECT * FROM (#{sql_without_semicolon}) AS chorus_view;"
    connection = schema.connect_as(current_user)
    query = CancelableQuery.new(connection, task[:check_id], current_user)
    result = query.execute(sql, :limit => ChorusConfig.instance['default_preview_row_limit'])
    present(result, :status => :ok)
  end
end
