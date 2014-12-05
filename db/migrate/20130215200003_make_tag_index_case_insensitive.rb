class MakeTagIndexCaseInsensitive < ActiveRecord::Migration
  def up
    remove_index :tags, :name
    execute "CREATE UNIQUE INDEX index_tags_on_lowercase_name ON tags ((lower(name)));"
  end

  def down
    execute "DROP INDEX index_tags_on_lowercase_name;"
    add_index :tags, :name, :unique => true
  end
end
