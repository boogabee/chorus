class AddHawqFlagToDataSources < ActiveRecord::Migration
  def change
    add_column :data_sources, :is_hawq, :boolean
  end
end
