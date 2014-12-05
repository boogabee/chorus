class ExternalTablesController < ApplicationController
  include DataSourceAuth

  wrap_parameters :hdfs_external_table, :exclude => []

  def create
    workspace = Workspace.find(params[:workspace_id])
    table_params = params[:hdfs_external_table]

    hdfs_entry = HdfsEntry.find(table_params[:hdfs_entry_id]) if table_params[:hdfs_entry_id]
    hdfs_dataset = Dataset.find(table_params[:hdfs_dataset_id]) if table_params[:hdfs_dataset_id]
    entry_or_dataset = hdfs_entry || hdfs_dataset

    unless workspace.sandbox
      present_validation_error(:EMPTY_SANDBOX)
      return
    end

    account = authorized_account(workspace.sandbox)
    connection = workspace.sandbox.connect_with(account)

    file_pattern =
        case table_params[:path_type]
          when "directory" then
            "*"
          when "pattern" then
            table_params[:file_pattern]
        end

    e = ExternalTable.build(
      :column_names => table_params[:column_names],
      :column_types => table_params[:types],
      :connection => connection,
      :delimiter => table_params[:delimiter],
      :file_pattern => file_pattern,
      :sandbox_data_source => workspace.sandbox.data_source,
      :entry_or_dataset => entry_or_dataset,
      :name => table_params[:table_name]
    )
    if e.save
      workspace.sandbox.refresh_datasets(account)
      dataset = workspace.sandbox.reload.datasets.find_by_name!(table_params[:table_name])
      create_event(dataset, workspace, entry_or_dataset, table_params)
      render :json => {}, :status => :ok
    else
      raise ApiValidationError.new(e.errors)
    end
  end

  private

  def present_validation_error(error_code)
    present_errors({:fields => {:external_table => {error_code => {}}}},
                   :status => :unprocessable_entity)
  end

  def create_event(dataset, workspace, entry_or_dataset, table_params)
    event_params = {:workspace => workspace, :dataset => dataset, :hdfs_entry => entry_or_dataset }

    if entry_or_dataset.is_a?(HdfsDataset)
      return Events::HdfsDatasetExtTableCreated.by(current_user).add(event_params.merge hdfs_dataset: entry_or_dataset)
    end

    case table_params[:path_type]
      when "directory" then
        Events::HdfsDirectoryExtTableCreated.by(current_user).add(event_params)
      when "pattern" then
        Events::HdfsPatternExtTableCreated.by(current_user).add(event_params.merge file_pattern: table_params[:file_pattern])
      else
        Events::HdfsFileExtTableCreated.by(current_user).add(event_params)
    end
  end
end
