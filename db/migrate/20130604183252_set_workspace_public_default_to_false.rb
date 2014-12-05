class SetWorkspacePublicDefaultToFalse < ActiveRecord::Migration
  def up
    execute "ALTER TABLE workspaces ALTER COLUMN public SET DEFAULT false"
  end

  def down
    execute "ALTER TABLE workspaces ALTER COLUMN public SET DEFAULT true"
  end
end
