require 'stale'

class GpdbDataset < RelationalDataset
  delegate :definition, :to => :statistics
  delegate :database, :to => :schema

  unscoped_belongs_to :schema, :class_name => 'GpdbSchema'

  def data_source_account_ids
    database.data_source_account_ids
  end

  def found_in_workspace_id
    (bound_workspace_ids + schema.workspaces.where(:show_sandbox_datasets => true).pluck(:id)).uniq
  end

  def self.total_entries(account, schema, options = {})
    schema.dataset_count account, options
  end

  def self.visible_to(*args)
    refresh(*args)
  end

  def database_name
    database.name
  end

  def column_type
    "GpdbDatasetColumn"
  end

  def execution_location
    database
  end

  private

  def create_import_event(params, user)
    workspace = Workspace.find(params[:workspace_id])
    dst_table = workspace.sandbox.datasets.find_by_name(params[:to_table]) unless params[:new_table].to_s == "true"
    Events::WorkspaceImportCreated.by(user).add(
        :workspace => workspace,
        :source_dataset => self,
        :dataset => dst_table,
        :destination_table => params[:to_table]
    )
  end
end
