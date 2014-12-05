class SearchController < ApplicationController
  before_filter :require_admin, :only => [:reindex]
  before_filter :require_full_search, :only => [:show, :workspaces]

  def show
    present Search.new(current_user, params)
  end

  def workspaces
    present MyWorkspacesSearch.new(current_user, params), :presenter_options => { :presenter_class => 'SearchPresenter' }
  end

  def type_ahead
    present TypeAheadSearch.new(current_user, params)
  end

  def reindex
    QC.enqueue_if_not_queued("SolrIndexer.refresh_and_reindex", params.fetch(:types) { 'all' })
    render :json => {}
  end
end
