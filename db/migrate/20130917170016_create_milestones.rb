class CreateMilestones < ActiveRecord::Migration
  def change
    create_table :milestones do |t|
      t.string :name
      t.string :status
      t.date :target_date
      t.belongs_to :workspace

      t.timestamps
    end
    add_index :milestones, :workspace_id
  end
end
