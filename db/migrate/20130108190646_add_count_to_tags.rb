class AddCountToTags < ActiveRecord::Migration
  def up
    add_column :tags, :taggings_count, :integer, { :null => false, :default => 0 }

    Tag.all.each do |tag|
      Tag.reset_all_counters(tag.id, :taggings)
    end
  end

  def down
    remove_column :tags, :taggings_count
  end
end
