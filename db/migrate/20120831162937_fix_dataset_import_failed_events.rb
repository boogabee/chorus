class FixDatasetImportFailedEvents < ActiveRecord::Migration
  def up
    dataset_import_failed_events = select_all "select id, additional_data, action from events where action = 'Events::DatasetImportFailed'"
    dataset_import_failed_events.each do |event|
      event_id = event['id']
      source_dataset_id =  JSON.parse(event['additional_data'])['source_dataset_id']
      next unless source_dataset_id
      execute "update events set target2_type='Dataset', target2_id=#{source_dataset_id} where id=#{event_id}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
