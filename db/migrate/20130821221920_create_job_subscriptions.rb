class CreateJobSubscriptions < ActiveRecord::Migration
  def change
    create_table :job_subscriptions do |t|
      t.integer :user_id, :null => false
      t.integer :job_id, :null => false
      t.string :condition

      t.timestamps
    end
    add_index :job_subscriptions, [:job_id, :condition, :user_id]
  end
end
