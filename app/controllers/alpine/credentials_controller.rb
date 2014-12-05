module Alpine
  class CredentialsController < AlpineController
    def show
      data_source = DataSource.find(params[:data_source_id])
      account = data_source.account_for_user!(current_user)
      present(account, :presenter_options => {:presenter_class => :CredentialsPresenter})
    end
  end
end