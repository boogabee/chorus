class RemoveTaggingsAndTags < ActiveRecord::Migration
  def up
    remove_index :taggings, :column => [:entity_id, :entity_type, :tag_id]
    drop_table :taggings

    remove_index :tags, :column => :name
    drop_table :tags
  end

  def down
    create_table :tags do |t|
      t.string :name, :null => false
      t.timestamps
    end
    add_index :tags, :name, :unique => true

    create_table :taggings do |t|
      t.integer :entity_id, :null => false
      t.string :entity_type, :null => false
      t.integer :tag_id, :null => false
      t.timestamps
    end

    add_index :taggings, [:entity_id, :entity_type, :tag_id], :unique => true
  end
end
