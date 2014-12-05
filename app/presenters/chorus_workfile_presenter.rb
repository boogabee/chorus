class ChorusWorkfilePresenter < WorkfilePresenter

  def to_hash
    if options[:workfile_as_latest_version] && model.latest_workfile_version
      version_options = options.dup
      version_options.delete :workfile_as_latest_version

      return present(model.latest_workfile_version, version_options)
    end

    workfile = super

    unless rendering_activities? || options[:list_view]
      workfile.merge!({
                          :has_draft => model.has_draft(current_user)
                      })
    end
    workfile[:execution_schema] = present(model.execution_schema, options.merge(:succinct => options[:list_view])) if options[:include_execution_schema]
    workfile
  end

  def complete_json?
    options[:include_execution_schema] && super
  end
end
