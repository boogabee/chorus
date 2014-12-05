class RelationalDataset < Dataset

  validates_uniqueness_of :name, :scope => [:schema_id, :type, :deleted_at]

  def source_dataset_for(workspace)
    schema_id != workspace.sandbox_id
  end

  def found_in_workspace_id
    bound_workspace_ids
  end

  def database_name
    ''
  end

  def scoped_name
    %("#{schema_name}"."#{name}")
  end

  def execution_location
    data_source
  end

  def data_source_account_ids
    schema.data_source_account_ids
  end

  def in_workspace?(workspace)
    self.bound_workspaces.include?(workspace) || workspace.sandbox.datasets.include?(self)
  rescue NoMethodError
    false
  end

  def associable?
    true
  end

  def can_import_into(destination)
    destination_columns = destination.column_data
    source_columns = column_data

    consistent_size = source_columns.size == destination_columns.size

    consistent_size && source_columns.all? do |source_column|
      destination_columns.find { |destination_column| source_column.match?(destination_column) }
    end
  end
end
