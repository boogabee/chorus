require 'spec_helper'

describe DataSourceStatusChecker do
  describe '.check_all' do
    let(:offline)     { mock!.check_status! { false }.subject }
    let(:online)      { mock!.check_status! { true }.subject }
    let(:explosive)   { mock!.check_status! { raise 'Quack' }.subject }
    let(:datasources) { [offline, online, explosive] }

    let(:hdfs_offline)     { mock!.check_status! { false }.subject }
    let(:hdfs_online)      { mock!.check_status! { true }.subject }
    let(:hdfs_explosive)   { mock!.check_status! { raise 'Quack' }.subject }
    let(:hdfs_datasources) { [hdfs_offline, hdfs_online, hdfs_explosive] }
    
    before do
      mock(DataSource).find_each do |arg|
        datasources.each { |datasource| arg.call(datasource)}
      end

      mock(HdfsDataSource).find_each do |arg|
        hdfs_datasources.each { |datasource| arg.call(datasource)}
      end
    end
    
    it 'checks the status of each data source' do
      DataSourceStatusChecker.check_all
    end
  end
end

