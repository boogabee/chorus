class AddUniqueConstraintToActsAsTaggable < ActiveRecord::Migration
  def change
    add_index :taggings, [:taggable_id, :taggable_type, :tag_id], :unique => true
    add_index :tags, :name, :unique => true
  end
end
