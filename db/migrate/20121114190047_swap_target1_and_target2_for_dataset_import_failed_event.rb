class SwapTarget1AndTarget2ForDatasetImportFailedEvent < ActiveRecord::Migration
  def change
    execute <<-SQL
    UPDATE events SET
        target1_id = old.target2_id,
        target1_type = old.target2_type,
        target2_id = old.target1_id,
        target2_type = old.target1_type
    FROM events old
    WHERE events.id = old.id
      AND events.action = 'Events::DatasetImportFailed';
    SQL
  end
end
