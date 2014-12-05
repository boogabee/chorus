module DataSources
  class AccountsController < ApplicationController
    def show
      present DataSource.find(params[:data_source_id]).account_for_user(current_user)
    end

    def create
      present updated_account, :status => :created
    end

    def update
      present updated_account, :status => :ok
    end

    def destroy
      data_source = DataSource.unshared.find(params[:data_source_id])
      data_source.account_for_user(current_user).destroy
      render :json => {}
    end

    private

    def updated_account
      data_source = DataSource.find(params[:data_source_id])

      account = data_source.account_for_user(current_user) || data_source.accounts.build(:owner => current_user)
      authorize! :update, account
      account.attributes = params[:account]

      authorize! :update, account

      account.save!
      account
    end
  end
end
