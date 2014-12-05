class DataSourcesController < ApplicationController
  include DataSourceAuth

  wrap_parameters :data_source, :exclude => []

  before_filter :find_data_source, :only => [:show, :update, :destroy]
  before_filter :demo_mode_filter, :only => [:create, :update, :destroy]
  before_filter :require_data_source_create, :only => [:create]

  def index
    succinct = params[:succinct] == 'true'
    includes = succinct ? [] : [{:owner => :tags}, :tags]
    data_sources = DataSource.by_type(params[:entity_type]).includes(includes)
    data_sources = data_sources.accessible_to(current_user) unless params[:all]

    present paginate(data_sources), :presenter_options => {:succinct => succinct}
  end

  def show
    present @data_source
  end

  def create
    entity_type = params[:data_source].delete(:entity_type)
    data_source = DataSource.create_for_entity_type(entity_type, current_user, params[:data_source])
    present data_source, :status => :created
  end

  def update
    authorize! :edit, @data_source
    @data_source.update_attributes!(params[:data_source])
    present @data_source
  end

  def destroy
    authorize! :edit, @data_source
    @data_source.destroy
    head :ok
  end

  private

  def find_data_source
    @data_source = DataSource.find(params[:id])
  end
end
