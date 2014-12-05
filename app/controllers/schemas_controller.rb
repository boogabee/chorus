class SchemasController < ApplicationController
  include DataSourceAuth

  def show
    schema = Schema.find(params[:id])
    authorize_data_source_access(schema)
    schema.verify_in_source(current_user)

    present schema
  end
end
