class ImportPresenter < Presenter

  def to_hash
    {
        :id => model.id,
        :to_table => model.to_table,
        :started_stamp => model.created_at,
        :completed_stamp => model.finished_at,
        :success => model.success,
        :source_dataset => source_dataset,
        :file_name => model.file_name,
        :workspace_id => model.workspace_id,
        :entity_type => model.entity_type_name
    }.merge(destination_dataset)
  end

  def source_dataset
    hide_source = model.source_id.nil?
    {
        :id => hide_source ? nil : model.source_id,
        :object_name => hide_source ? nil : model.source.try(:name)
    }
  end

  def destination_dataset
    dataset_hash = {
        :id => model.destination_dataset ? model.destination_dataset_id : nil,
        :object_name => model.to_table
    }
    {:destination_dataset => dataset_hash}
  end
end

