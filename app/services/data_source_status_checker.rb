class DataSourceStatusChecker
  def self.check_all
    DataSource.find_each { |source| self.check(source) }

    HdfsDataSource.find_each { |source| self.check(source) }
  end

  def self.check(data_source)
    data_source.check_status!
  rescue => e
    pa "Unable to check status of DataSource: #{data_source.inspect}"
    pa "Exception: #{e}"
  end
end