module DataSources
  class OwnersController < ApplicationController
    def update
      authorize! :edit, data_source
      DataSourceOwnership.change(current_user, data_source, new_owner)
      present data_source
    end

    private

    def new_owner
      User.find(params[:owner][:id])
    end

    def data_source
      @data_source ||= DataSource.owned_by(current_user).find(params[:data_source_id])
    end
  end
end
