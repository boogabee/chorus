module DataSources
  class WorkspaceDetailsController < ApplicationController
    def show
      data_source = DataSource.where(type: %w(GpdbDataSource PgDataSource)).find(params[:data_source_id])
      present data_source, :presenter_options => {:presenter_class => :DataSourceWorkspaceDetailPresenter}
    end
  end
end
