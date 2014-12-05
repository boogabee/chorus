class AddTaggings < ActiveRecord::Migration
  def up
    create_table :taggings do |t|
      t.integer :entity_id, :null => false
      t.string :entity_type, :null => false
      t.integer :tag_id, :null => false
      t.timestamps
    end

    add_index :taggings, [:entity_id, :entity_type, :tag_id], :unique => true
  end

  def down
    remove_index :taggings, :column => [:entity_id, :entity_type, :tag_id]
    drop_table :taggings
  end
end
