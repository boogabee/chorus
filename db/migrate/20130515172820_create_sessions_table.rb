class CreateSessionsTable < ActiveRecord::Migration
  def up
    create_table :sessions do |t|
      t.string :session_id, :limit => 40
      t.integer :user_id
      t.timestamps
    end
    add_index :sessions, :session_id, :unique => true
    remove_column :users, :api_key
  end

  def down
    drop_table :sessions
    add_column :users, :api_key, :string, :length => 40
    add_index :users, :api_key, :unique => true
  end
end
