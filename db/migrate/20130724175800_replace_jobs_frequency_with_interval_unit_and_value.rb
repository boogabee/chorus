class ReplaceJobsFrequencyWithIntervalUnitAndValue < ActiveRecord::Migration
  def up
    add_column :jobs, :interval_unit, :string
    add_column :jobs, :interval_value, :integer
    remove_column :jobs, :frequency
  end

  def down
    add_column :jobs, :frequency, :string
    remove_column :jobs, :interval_value, :interval_unit
  end
end
