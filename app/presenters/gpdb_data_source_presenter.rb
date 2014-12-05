class GpdbDataSourcePresenter < DataSourcePresenter

  def to_hash
    super.merge(specific_data)
  end

  private

  def specific_data
    return {} if succinct?
    {
        :is_deleted => !model.deleted_at.nil?,
        :data_source_provider => model.data_source_provider,
    }
  end
end
