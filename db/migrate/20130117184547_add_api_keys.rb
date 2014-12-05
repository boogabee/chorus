class AddApiKeys < ActiveRecord::Migration
  class MigrationUser < ActiveRecord::Base
    self.table_name = :users
  end

  def up
    add_column :users, :api_key, :string, :length => 40
    add_index :users, :api_key, :unique => true
    MigrationUser.all.each do |u|
      u.api_key = SecureRandom.hex(20)
      u.save!
    end
  end

  def down
    remove_index :users, :api_key, :unique => true
    remove_column :users, :api_key
  end
end
