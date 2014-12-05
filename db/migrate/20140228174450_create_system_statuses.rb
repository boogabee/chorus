class CreateSystemStatuses < ActiveRecord::Migration
  def change
    create_table :system_statuses do |t|
      t.boolean :expired, :default => false
      t.boolean :user_count_exceeded, :default => false
      t.string :message, :limit => 2048
      t.timestamps
    end
  end
end
