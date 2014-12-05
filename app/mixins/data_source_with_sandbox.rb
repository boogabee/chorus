module DataSourceWithSandbox
  extend ActiveSupport::Concern

  included do
    has_many :databases, :foreign_key => 'data_source_id'
    has_many :schemas, :through => :databases
    has_many :datasets, :through => :schemas

    has_many :workspaces, :through => :schemas, :foreign_key => 'sandbox_id'
  end

  def used_by_workspaces(viewing_user)
    workspaces.includes({:sandbox => {:scoped_parent => :data_source }}, :owner).workspaces_for(viewing_user).order('lower(workspaces.name), id')
  end

end
