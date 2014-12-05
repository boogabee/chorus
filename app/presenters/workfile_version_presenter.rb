class WorkfileVersionPresenter < Presenter

  def to_hash
    workfile_hash.merge({
      :version_info => {
        :id => model.id,
        :version_num => model.version_num,
        :commit_message => model.commit_message,
        :owner => owner_hash,
        :modifier => modifier_hash,
        :created_at => model.created_at,
        :updated_at => model.updated_at,
        :content_url => model.contents.url,
        :partial_file => partial_file?,
        :icon_url => icon_url,
        :content => content_value
      }
    })
  end

  def partial_file?
    model.contents_file_size > max_presentable_content_size
  end

  def workfile_hash
    present(model.workfile, options.merge(:include_execution_schema => true))
  end

  def content_value
    options[:contents] ? model.get_content(max_presentable_content_size) : nil
  end

  def max_presentable_content_size
    (1.megabyte/8).to_i
  end

  def owner_hash
    rendering_activities? ? { :id => model.owner_id } : present(model.owner, options.merge(:succinct => true))
  end

  def modifier_hash
    rendering_activities? ? { :id => model.modifier_id } : present(model.modifier, options.merge(:succinct => true))
  end

  def icon_url
    model.contents.url(:icon) if model.image?
  end

  def complete_json?
    !rendering_activities? && options[:contents]
  end
end
