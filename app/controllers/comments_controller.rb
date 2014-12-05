class CommentsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_filter :sanitize_body, :only => [:create]

  def show
    comment = Comment.find(params[:id])
    authorize! :show, comment
    present comment
  end

  def create
    comment = Comment.new
    attributes = params[:comment]
    attributes[:author_id] = current_user.id
    comment.attributes = attributes

    authorize! :create_comment_on, Comment, Events::Base.find(comment.event_id)
    comment.save!

    event = comment.event
    users_to_notify = event.comments.map(&:author_id)
    users_to_notify << event.actor_id
    users_to_notify = users_to_notify.uniq - [current_user.id]
    if event.is_a?(Events::Note)
      users_to_notify.each do |user_id|
        Notification.create!(
            :recipient_id => user_id,
            :event => event,
            :comment_id => comment.id
        )
      end
    end

    present comment, :status => :created
  end

  def destroy
    comment = Comment.find(params[:id])
    authorize! :destroy, comment

    comment.destroy
    render :json => {}
  end

  private

  def sanitize_body
    params[:comment][:body] = sanitize(params[:comment][:body]) if params[:comment][:body]
  end
end