class NotificationsController < ApplicationController
  def index
    notifications = current_user.notifications.order("created_at DESC").
      includes(:event => Events::Base.activity_stream_eager_load_associations).
      includes(:recipient, :comment)
    notifications = notifications.unread if params['type'] == 'unread'
    present paginate(notifications), :presenter_options => {:activity_stream => true, :succinct => true}
  end

  def read
    current_user.notifications.where(:id => params[:notification_ids]).update_all(:read => true)
    head :ok
  end

  def destroy
    notification = Notification.find(params[:id])
    authorize! :destroy, notification
    notification.destroy
    render :json => {}
  end
end