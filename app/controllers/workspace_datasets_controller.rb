class WorkspaceDatasetsController < ApplicationController
  include DataSourceAuth

  def index
    authorize! :show, workspace

    params[:limit] = params[:page].to_i * params[:per_page].to_i
    params[:name_filter] = params[:name_pattern]
    params[:total_entries] = workspace.dataset_count(current_user, params)

    datasets = workspace.datasets(current_user, params).includes(Dataset.eager_load_associations).list_order

    present paginate(datasets), :presenter_options => { :workspace => workspace }
  end

  def create
    authorize! :can_edit_sub_objects, workspace
    datasets = Dataset.where(:id => params[:dataset_ids])

    status = workspace.associate_datasets(current_user, datasets) ? :created : :unprocessable_entity

    render :json => {}, :status => status
  end

  def show
    authorize! :show, workspace

    dataset = params[:name] ? Dataset.find_by_name(params[:name]) : Dataset.find(params[:id])
    dataset.in_workspace?(workspace) or raise ActiveRecord::RecordNotFound

    authorize_data_source_access(dataset)

    if dataset.verify_in_source(current_user)
      dataset.mark_fresh!
      present dataset, {:presenter_options => {:workspace => workspace, :with_content => true}}
    else
      render_dataset_with_error(dataset)
    end

  rescue PostgresLikeConnection::DatabaseError => e
    render_dataset_with_error(dataset, e.error_type)
  end

  def render_dataset_with_error(dataset, error_type = :MISSING_DB_OBJECT)
    json = {
        :response => Presenter.present(dataset, view_context, {:workspace => workspace}),
        :errors => {:record => error_type}
    }
    render json: json, status: :unprocessable_entity
  end

  def destroy_multiple
    authorize! :can_edit_sub_objects, workspace
    associations = AssociatedDataset.where(:workspace_id => params[:workspace_id], :dataset_id => params[:dataset_ids])
    associations.destroy_all
    render :json => {}
  end

  def destroy
    authorize! :can_edit_sub_objects, workspace
    associations = AssociatedDataset.where(:workspace_id => params[:workspace_id], :dataset_id => [params[:id]])
    associations.destroy_all
    render :json => {}
  end

  private

  def workspace
    @workspace ||= Workspace.workspaces_for(current_user).find(params[:workspace_id])
  end
end

