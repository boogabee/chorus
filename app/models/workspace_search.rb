class WorkspaceSearch < Search
  attr_reader :workspace_id

  validates_presence_of :workspace_id

  def models_to_search
    super & [Workspace, Workfile, Dataset]
  end

  def build_search
    super.build do
      any_of do
        with :workspace_id, workspace_id if models_to_search.include?(Workspace) || models_to_search.include?(Workfile)
        with :found_in_workspace_id, workspace_id if models_to_search.include?(Dataset)
      end
    end
  end

  def num_found
    search.group(:grouping_id).total
  end

  def results
    @results ||= begin
      search.associate_grouped_notes_with_primary_records
      search.results
    end
  end

  private

  def count_using_facets?
    false
  end
end