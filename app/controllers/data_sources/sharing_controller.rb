module DataSources
  class SharingController < ApplicationController
    def create
      authorize! :edit, data_source

      data_source.shared = true
      data_source.accounts.where("id != #{data_source.owner_account.id}").destroy_all
      data_source.save!
      present data_source, :status => :created
    end

    def destroy
      authorize! :edit, data_source

      data_source.shared = false
      data_source.save!
      present data_source
    end

    private

    def data_source
      @data_source ||= DataSource.find(params[:data_source_id])
    end
  end
end