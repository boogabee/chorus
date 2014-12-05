class RenameGpdbSchemaDatasetsCountToActiveTablesAndViewsCount < ActiveRecord::Migration
  def change
    rename_column :gpdb_schemas, :datasets_count, :active_tables_and_views_count
  end
end
