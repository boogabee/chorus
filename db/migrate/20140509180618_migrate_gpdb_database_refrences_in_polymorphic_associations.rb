class MigrateGpdbDatabaseRefrencesInPolymorphicAssociations < ActiveRecord::Migration
  POLYMORPHS = {
      :schemas => 'parent_type',
      :data_source_account_permissions => 'accessed_type',
      :workfile_execution_locations => 'execution_location_type'
  }

  def up
    POLYMORPHS.each do |table, column|
      execute(%(UPDATE #{table} SET #{column}='Database' WHERE #{column}='GpdbDatabase'))
    end
  end

  def down
    POLYMORPHS.each do |table, column|
      execute(%(UPDATE #{table} SET #{column}='GpdbDatabase' WHERE #{column}='Database'))
    end
  end
end
