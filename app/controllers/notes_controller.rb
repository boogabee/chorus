class NotesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  def create
    note_params = params[:note]
    entity_type = note_params[:entity_type]
    entity_id = note_params[:entity_id]
    model = ModelMap.model_from_params(entity_type, entity_id)

    authorize! :create_note_on, model
    note_params[:body] = sanitize(note_params[:body])

    note = Events::Note.build_for(model, note_params)

    note.save!

    (note_params[:recipients] || []).each do |recipient_id|
      Notification.create!(:recipient_id => recipient_id, :event_id => note.id)
    end

    present note, :status => :created
  end

  def update
    note = Events::Base.find(params[:id])
    authorize! :update, note
    note.update_attributes!(:body => sanitize(params[:note][:body]))
    present note
  end

  def destroy
    note = Events::Base.find(params[:id])
    authorize! :destroy, note
    note.destroy
    render :json => {}
  end
end
