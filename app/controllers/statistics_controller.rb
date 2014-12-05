class StatisticsController < ApplicationController
  include DataSourceAuth

  def show
    dataset = Dataset.find(params[:dataset_id])
    account = authorized_account(dataset)
    statistics = DatasetStatistics.build_for(dataset, account)

    raise ActiveRecord::StatementInvalid, "Unable to generate statistics" unless statistics

    present statistics
  end
end
