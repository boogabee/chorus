class SetWorkspacePublicDefaultBackToTrue < ActiveRecord::Migration
  def up
    execute "ALTER TABLE workspaces ALTER COLUMN public SET DEFAULT true"
  end

  def down
    execute "ALTER TABLE workspaces ALTER COLUMN public SET DEFAULT false"
  end
end
