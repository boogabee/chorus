class GnipDataSourcesController < ApplicationController

  before_filter :demo_mode_filter, :only => [:create, :update, :destroy]
  before_filter :require_data_source_create, :only => [:create]

  def create
    data_source = Gnip::DataSourceRegistrar.create!(params[:gnip_data_source], current_user)
    present data_source, :status => :created
  end

  def index
    succinct = params[:succinct] == 'true'
    includes = succinct ? [] : [{:owner => :tags}, :tags]
    present paginate(GnipDataSource.scoped.includes(includes)), :presenter_options => {:succinct => succinct}
  end

  def show
    present GnipDataSource.find(params[:id])
  end

  def update
    gnip_params = params[:gnip_data_source]
    authorize! :owner, GnipDataSource.find(params[:id])
    data_source = Gnip::DataSourceRegistrar.update!(params[:id], gnip_params)

    present data_source
  end

  def destroy
    data_source = GnipDataSource.find(params[:id])
    authorize! :owner, data_source
    data_source.destroy

    head :ok
  end
end
