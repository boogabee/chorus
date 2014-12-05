class StatusController < ApplicationController
  skip_before_filter :require_login

  def show
    status = SystemStatusService.latest
    render :json => {
        :user_count_exceeded => status.user_count_exceeded?,
        :updated_at => status.updated_at,
        :status => 'Chorus is running'
    }
  end
end
