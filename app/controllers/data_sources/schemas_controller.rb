module DataSources
  class SchemasController < DataSourcesController
    def index
      data_source = DataSource.find(params[:data_source_id])
      present Schema.visible_to(authorized_account(data_source), data_source)
    end
  end
end