class HdfsEntryStatisticsPresenter < Presenter

  def to_hash
    {
      :owner => model.owner,
      :group => model.group,
      :modified_at => model.modified_at,
      :accessed_at => model.accessed_at,
      :file_size => model.file_size,
      :block_size => model.block_size,
      :permissions => model.permissions,
      :replication => model.replication
    }
  end

  def complete_json?
    true
  end
end