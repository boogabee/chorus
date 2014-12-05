class SessionsController < ApplicationController
  skip_before_filter :require_login, :except => :show
  skip_before_filter :extend_expiration
  before_filter :require_not_expired, :only => :create

  def create
    session_object = Session.create!(params[:session])
    session[:chorus_session_id] = session_object.session_id
    present session_object, :status => :created
  rescue ActiveRecord::RecordInvalid => e
    present_validation_errors e.record.errors, :status => :unauthorized
  end

  def destroy
    current_session.try(:destroy)
    session.clear
    render :json => {:csrf_token => form_authenticity_token}, :status => :ok
  end

  def show
    present current_session
  end

  private

  def require_not_expired
    present_errors({:service => :LICENSE_EXPIRED}, :status => :service_unavailable) if SystemStatusService.latest.expired?
  end
end
