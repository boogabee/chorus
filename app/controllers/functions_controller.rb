class FunctionsController < ApplicationController
  include DataSourceAuth

  def index
    schema = Schema.sandboxable.find(params[:schema_id])
    schema_functions = schema.stored_functions(authorized_account(schema))
    present paginate schema_functions
  end
end
