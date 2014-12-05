class DataSourceWorkspaceDetailPresenter < Presenter

  def to_hash
    account = model.account_for_user(current_user)
    return results_hash(nil, nil) unless account

    recommended_gb = ChorusConfig.instance['sandbox_recommended_size_in_gb']
    recommended_bytes = recommended_gb * 1024 * 1024 * 1024

    workspaces = []
    sandbox_sizes = {}

    credentials_invalid = false

    model.used_by_workspaces(current_user).each do |workspace|
      begin
        sandbox_size = workspace.sandbox.disk_space_used(account) unless credentials_invalid
      rescue => e
        credentials_invalid = true if (e.respond_to?(:error_type) && e.error_type == :INVALID_PASSWORD)
      end

      sandbox_sizes[workspace.sandbox.id] = sandbox_size || 0

      workspaces << {
          :id => workspace.id,
          :name => workspace.name,
          :size_in_bytes => sandbox_size,
          :percentage_used => sandbox_size ? (sandbox_size / recommended_bytes.to_f * 100).round : nil,
          :owner_full_name => workspace.owner.full_name,
          :schema_name => workspace.sandbox.name,
          :database_name => workspace.sandbox.database.name
      }
    end
    results_hash(workspaces, sandbox_sizes.values.sum)
  end

  def complete_json?
    true
  end

  private

  def results_hash(workspaces, sandbox_size)
    {
        :workspaces => workspaces,
        :sandboxes_size_in_bytes => sandbox_size
    }
  end
end
