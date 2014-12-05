module ImportConsole
  class ImportsController < ApplicationController
    before_filter :require_login
    before_filter :require_admin

    def require_login
      return if logged_in? && !current_session.expired?
      redirect_to url_for(:port => ChorusConfig.instance['server_port'],
                          :protocol => "http",
                          :controller => "/root",
                          :action => "index")
    end

    def index
      @imports = Import.where(:finished_at => nil).map do |import|
        ImportManager.new(import)
      end
    end
  end
end
