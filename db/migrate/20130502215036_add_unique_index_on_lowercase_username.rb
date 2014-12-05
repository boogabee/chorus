class AddUniqueIndexOnLowercaseUsername < ActiveRecord::Migration
  def up
    execute "CREATE UNIQUE INDEX index_users_on_lower_case_username ON users (lower(username)) WHERE deleted_at IS NULL;"
  end

  def down
    execute "DROP INDEX index_users_on_lower_case_username"
  end
end
