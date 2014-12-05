# Memberships allow access control to workspaces.
# They are not always useful for associating users to workspaces,
# since admins can create objects within a workspace
# without having a membership.
class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :workspace
  validates_presence_of :user
  validates_presence_of :workspace
end
