class AddTargetThreeToEvents < ActiveRecord::Migration
  class MigrationEvents < ActiveRecord::Base
    self.table_name = :events
    serialize :additional_data, JsonHashSerializer
  end

  def up
    add_column :events, :target3_type, :string
    add_column :events, :target3_id, :integer

    MigrationEvents.where(:action => ['Events::SchemaImportFailed', 'Events::SchemaImportCreated']).find_each do |event|
      schema_id = event.additional_data.delete('schema_id')
      event.target3_id = schema_id
      event.target3_type = 'Schema'
      event.save!
    end
  end
  
  def down
    MigrationEvents.where(:action => ['Events::SchemaImportFailed', 'Events::SchemaImportCreated']).find_each do |event|
      event.additional_data['schema_id'] = event.target3_id
      event.save!
    end

    remove_column :events, :target3_type
    remove_column :events, :target3_id
  end
end
