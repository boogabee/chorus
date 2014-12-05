class HdfsDatasetStatisticsPresenter < Presenter
  def to_hash
    { :file_mask => model.file_mask }
  end

  def complete_json?
    true
  end
end