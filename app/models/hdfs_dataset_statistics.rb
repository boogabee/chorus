class HdfsDatasetStatistics
  attr_reader :file_mask

  def initialize(attributes)
    @file_mask = attributes.fetch('file_mask')
  end
end