class DatabaseSchemasController < ApplicationController
  include DataSourceAuth

  def index
    database = Database.find(params[:database_id])
    schemas = Schema.visible_to(authorized_account(database), database)
    present paginate schemas
  end
end
