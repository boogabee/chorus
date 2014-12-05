require 'allowy'
require 'hdfs_data_source_access'

class HdfsDataSourcesController < ApplicationController

  before_filter :demo_mode_filter, :only => [:create, :update, :destroy]
  before_filter :require_data_source_create, :only => [:create]

  def create
    data_source = Hdfs::DataSourceRegistrar.create!(params[:hdfs_data_source], current_user)
    QC.enqueue_if_not_queued("HdfsDataSource.refresh", data_source.id)
    present data_source, :status => :created
  end

  def index
    succinct = params[:succinct] == 'true'
    includes = succinct ? [] : [{:owner => :tags}, :tags]
    hdfs_data_sources = HdfsDataSource.scoped.includes(includes)
    hdfs_data_sources = hdfs_data_sources.with_job_tracker if params[:job_tracker]
    present paginate(hdfs_data_sources), :presenter_options => {:succinct => succinct}
  end

  def show
    present HdfsDataSource.find(params[:id])
  end

  def update
    hdfs_data_source = HdfsDataSource.find(params[:id])
    authorize! :edit, hdfs_data_source

    hdfs_data_source = Hdfs::DataSourceRegistrar.update!(hdfs_data_source.id, params[:hdfs_data_source], current_user)
    present hdfs_data_source
  end

  def destroy
    hdfs_data_source = HdfsDataSource.find(params[:id])
    authorize! :edit, hdfs_data_source
    hdfs_data_source.destroy
    head :ok
  end
end
