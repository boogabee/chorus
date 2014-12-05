class HdfsFile
  attr_reader :hdfs_data_source, :path

  def initialize(path, hdfs_data_source, attributes={})
    @attributes = attributes
    @hdfs_data_source = hdfs_data_source
    @path = path
  end

  def contents
    hdfs_query = Hdfs::QueryService.for_data_source(hdfs_data_source)
    hdfs_query.show(path)
  end

  def modified_at
    @attributes[:modified_at]
  end

  def url
    hdfs_data_source.url.chomp('/') + path
  end
end
