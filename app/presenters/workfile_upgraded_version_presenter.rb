class WorkfileUpgradedVersionPresenter < EventPresenter
  def child_presenter_hash
    {
        'version_is_deleted' => model.version_is_deleted?
    }
  end
end