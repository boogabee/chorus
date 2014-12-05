class MilestonePresenter < Presenter

  def to_hash
    {
      :id => model.id,
      :workspace => present(model.workspace, options.merge(:succinct => options[:succinct] || options[:list_view])),
      :name => model.name,
      :target_date => model.target_date,
      :state => model.state
    }
  end

end
