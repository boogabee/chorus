class LicensePresenter < Presenter
  KEYS = [:admins, :developers, :collaborators, :level, :vendor, :organization_uuid, :expires]

  def to_hash
    KEYS.inject({}) do |memo, key|
      memo[key] = model[key]
      memo
    end.merge({
            :workflow_enabled => model.workflow_enabled?,
            :advisor_now_enabled => model.advisor_now_enabled?,
            :branding => model.branding,
            :limit_search => model.limit_search?,
            :limit_workspace_membership => model.limit_workspace_membership?,
            :limit_milestones => model.limit_milestones?,
            :limit_jobs => model.limit_jobs?,
            :limit_sandboxes => model.limit_sandboxes?,
            :home_page => model.home_page
    })
  end
end
