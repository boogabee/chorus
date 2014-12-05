class ResetOracleDatasetCounts < ActiveRecord::Migration
  def up
    OracleSchema.all.each do |schema|
      Schema.reset_counters(schema.id, :active_tables_and_views)
    end
  end

  def down
  end
end
