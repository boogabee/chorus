class DatasetStatisticsPresenter < Presenter

  def to_hash
    {
        :object_type => model.table_type,
        :rows => model.row_count,
        :columns => model.column_count,
        :description => model.description,
        :last_analyzed_time => model.last_analyzed,
        :on_disk_size => model.disk_size,
        :partitions => model.partition_count,
        :definition => model.definition,
        :entity_type => model.entity_type_name
    }
  end

  def complete_json?
    true
  end
end