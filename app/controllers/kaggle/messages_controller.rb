class Kaggle::MessagesController < ApplicationController
  wrap_parameters :kaggle_message, :include => ['reply_to', 'html_body', 'subject', 'recipient_ids', 'workspace_id']

  def create
    kaggleParams = prepared_parameters(params[:kaggle_message])
    Kaggle::API.send_message(kaggleParams)
    render :json => {}, :status => :created
  rescue Kaggle::API::MessageFailed => e
    raise ModelNotCreated.new(e.message)
  end

  private
  def prepared_parameters(input_params)
    params = {}
    params["apiKey"] =  ChorusConfig.instance['kaggle.api_key']
    params["subject"] = input_params["subject"]
    params["userId"] = input_params["recipient_ids"]
    params["htmlBody"] = input_params["html_body"].gsub(/\n/, '<br>')
    params["replyTo"] = input_params["reply_to"]
    params
  end
end