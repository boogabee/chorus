class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.text :name
      t.boolean :enabled
      t.belongs_to :workspace

      t.timestamps
    end
    add_index :jobs, :workspace_id
  end
end
