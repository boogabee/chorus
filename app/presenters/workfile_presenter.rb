class WorkfilePresenter < Presenter
  def to_hash
    recent_comments = Array.wrap(recent_comment)

    workfile = {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :file_name => model.file_name,
      :file_type => model.content_type,
      :latest_version_id => model.latest_workfile_version_id,
      :is_deleted => model.deleted?,
      :recent_comments => present(recent_comments, :as_comment => true),
      :comment_count => recent_comments.empty? ? 0 : model.comments.count + model.notes.count,
      :tags => present(model.tags, options),
      :entity_type => model.entity_type_name,
      :entity_subtype => model.entity_subtype,
      :user_modified_at => model.user_modified_at,
      :status => model.status
    }

    unless rendering_activities?
      workfile.merge!({
        :owner => present(model.owner, :succinct => true),
      })
    end
    workfile
  end

  def complete_json?
    !rendering_activities?
  end

  private

  def recent_comment
    [model.most_recent_notes.last, model.most_recent_comments.last].compact.sort_by(&:created_at).last
  end
end
