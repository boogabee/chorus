class Hdfs::StatisticsController < ApplicationController

  def show
    statistics = hdfs_entry.statistics

    present statistics
  end

  private

  def hdfs_entry
    @hdfs_entry ||= HdfsEntry.find(params[:file_id])
  end

  def hdfs_data_source
    @hdfs_data_source ||= HdfsDataSource.find(params[:hdfs_data_source_id])
  end
end
