class ChorusViewsController < ApplicationController
  wrap_parameters :chorus_view, :exclude => [:id]

  def create
    chorus_view = ChorusView.new(params[:chorus_view])
    authorize! :can_edit_sub_objects, chorus_view.workspace

    if (params[:chorus_view][:source_object_type] == 'workfile')
      source_object = Workfile.find(params[:chorus_view][:source_object_id])
    else
      source_object = Dataset.find(params[:chorus_view][:source_object_id])
    end

    ChorusView.transaction do
      chorus_view.save!
      Events::ChorusViewCreated.by(current_user).add(
          :workspace => chorus_view.workspace,
          :source_object => source_object,
          :dataset => chorus_view
      )
    end

    present chorus_view, :status => :created
  end

  def duplicate
    old_chorus_view = ChorusView.find(params[:id])
    chorus_view = old_chorus_view.create_duplicate_chorus_view(params[:chorus_view][:object_name])

    authorize! :can_edit_sub_objects, chorus_view.workspace

    ChorusView.transaction do
      chorus_view.save!

      Events::ChorusViewCreated.by(current_user).add(
          :workspace => chorus_view.workspace,
          :source_object => old_chorus_view,
          :dataset => chorus_view
      )
    end
    present chorus_view, :presenter_options => {:workspace => chorus_view.workspace}, :status => :created
  end

  def update
    chorus_view = ChorusView.find(params[:id])
    authorize! :can_edit_sub_objects, chorus_view.workspace
    ChorusView.transaction do
      chorus_view.update_attributes!(params[:chorus_view])

      Events::ChorusViewChanged.by(current_user).add(
          :workspace => chorus_view.workspace,
          :dataset => chorus_view
      )
    end
    present chorus_view
  end

  def destroy
    chorus_view = ChorusView.find(params[:id])
    authorize! :can_edit_sub_objects, chorus_view.workspace
    chorus_view.destroy

    render :json => {}
  end

  def convert
    chorus_view = ChorusView.find(params[:id])
    authorize! :can_edit_sub_objects, chorus_view.workspace

    database_view = chorus_view.convert_to_database_view(params[:object_name], current_user)
    Events::ViewCreated.by(current_user).add(
        :workspace => chorus_view.workspace,
        :dataset => database_view,
        :source_dataset => chorus_view
    )
    render :json => {}, :status => :created
  end
end