class CreateTableDashboardItems < ActiveRecord::Migration
  def change
    create_table :dashboard_items do |t|
      t.references :user

      t.string :name
      t.integer :location
      t.timestamps
    end
  end
end
