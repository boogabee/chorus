class AnalyzeController < ApplicationController
  include DataSourceAuth

  def create
    dataset = Dataset.find(params[:table_id])
    dataset.analyze(authorized_account(dataset))
    present([], :status => :ok)
  end
end