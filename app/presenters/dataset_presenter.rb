class DatasetPresenter < Presenter

  def to_hash
    succinct? ? succinct_hash : complete_hash
  end

  def succinct_hash
    {
        :id => model.id,
        :object_name => model.name,
        :schema => schema_hash,
        :entity_type => model.entity_type_name,
        :entity_subtype => subtype,
        :stale => model.stale?,
        :is_deleted => model.deleted?
    }.merge(associated_workspaces_hash)
  end

  def complete_hash
    {
        :recent_comments => present(recent_comments, :as_comment => true),
        :comment_count => recent_comments.empty? ? 0 : model.comments.count + model.notes.count
    }.merge(succinct_hash).
        merge(workspace_hash).
        merge(credentials_hash).
        merge(tableau_workbooks_hash).
        merge(tags_hash)
  end

  def complete_json?
    !rendering_activities? && !succinct?
  end

  private

  def recent_comments
    Array.wrap [model.most_recent_notes.last, model.most_recent_comments.last].compact.sort_by(&:created_at).last
  end

  def tags_hash
    rendering_activities? ? {} : {:tags => present(model.tags)}
  end

  def schema_hash
    present(model.schema, options.merge({:succinct => true}))
  end

  def subtype
    if sandbox_table?
      "SANDBOX_TABLE"
    else
      "SOURCE_TABLE"
    end
  end

  def sandbox_table?
    options[:workspace] && !model.source_dataset_for(options[:workspace]) unless model.is_a?(HdfsDataset)
  end

  def workspace_hash
    options[:workspace] ? {:workspace => present(options[:workspace], @options)} : {}
  end

  def credentials_hash
    if rendering_activities? || succinct? || (sandbox_table? && !model.is_a?(ChorusView))
      {:has_credentials => true}
    else
      {:has_credentials => model.accessible_to(current_user)}
    end
  end

  def associated_workspaces_hash
    return {:associated_workspaces => []} if rendering_activities?
    workspaces = model.bound_workspaces.map do |workspace|
      {:id => workspace.id, :name => workspace.name}
    end

    {:associated_workspaces => workspaces}
  end

  def tableau_workbooks_hash
    return {} unless has_tableau_workbooks?
    return {:tableau_workbooks => []} if rendering_activities?
    tableau_workbooks = model.tableau_workbook_publications.map do |workbook|
      {:id => workbook.id,
       :name => workbook.name,
       :url => workbook.workbook_url
      }
    end

    {:tableau_workbooks => tableau_workbooks}
  end

  def has_tableau_workbooks?
    false
  end
end
