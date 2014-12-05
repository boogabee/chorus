class AddUniqueContraintToSchemasNames < ActiveRecord::Migration
  def up
    cleanup
    add_index :schemas, [:name, :parent_id, :parent_type], :unique => true
  end

  def down
    remove_index :schemas, [:name, :parent_id, :parent_type]
  end

  def cleanup
    duplicate_schemas = select_all "select name, parent_id, parent_type, count(id) from schemas group by name, parent_id, parent_type having count(id) > 1"
    duplicate_schemas.each do |row|
      schema_ids = select_values sql_variable_inter_stringification("select id from schemas where name = :name and parent_id = :parent_id and parent_type = :parent_type order by id", :name => row["name"], :parent_id => row["parent_id"], :parent_type => row["parent_type"])
      original_schema_id = schema_ids.shift

      schema_ids.each do |old_schema_id|
        execute sql_variable_inter_stringification("update workfiles set execution_schema_id = :schema_id where execution_schema_id = :old_schema_id", :schema_id => original_schema_id, :old_schema_id => old_schema_id)
        execute sql_variable_inter_stringification("update workspaces set sandbox_id = :schema_id where sandbox_id = :old_schema_id", :schema_id => original_schema_id, :old_schema_id => old_schema_id)
        execute sql_variable_inter_stringification("update datasets set schema_id = :schema_id where schema_id = :old_schema_id and type = 'ChorusView'", :schema_id => original_schema_id, :old_schema_id => old_schema_id)

        duplicate_datasets = select_all sql_variable_inter_stringification("select id, name from datasets where schema_id = :schema_id", :schema_id => old_schema_id)
        duplicate_datasets.each do |dup_dataset|
          original_dataset_id = select_value sql_variable_inter_stringification("select id from datasets where schema_id = :original_schema and name = :name", :original_schema => original_schema_id, :name => dup_dataset["name"])
          unless original_dataset_id
            execute sql_variable_inter_stringification("insert into datasets (name, schema_id, created_at, updated_at) values (:name, :schema_id, :created_at, :created_at)", :name => dup_dataset["name"], :schema_id => original_schema_id, :created_at => Time.now)
            original_dataset_id = select_value sql_variable_inter_stringification("select id from datasets where schema_id = :original_schema and name = :name", :original_schema => original_schema_id, :name => dup_dataset["name"])
          end

          execute sql_variable_inter_stringification("update activities set entity_id = :original_dataset_id where entity_id = :dup_dataset_id and entity_type in ('Dataset', 'GpdbTable', 'OracleTable', 'GpdbView', 'OracleView')", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])
          execute sql_variable_inter_stringification("update events set target1_id = :original_dataset_id where target1_id = :dup_dataset_id and target1_type in ('Dataset', 'GpdbTable', 'OracleTable', 'GpdbView', 'OracleView')", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])
          execute sql_variable_inter_stringification("update events set target2_id = :original_dataset_id where target2_id = :dup_dataset_id and target2_type in ('Dataset', 'GpdbTable', 'OracleTable', 'GpdbView', 'OracleView')", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])

          execute sql_variable_inter_stringification("update associated_datasets set dataset_id = :original_dataset_id where dataset_id = :dup_dataset_id", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])
          execute sql_variable_inter_stringification("update import_schedules set source_dataset_id = :original_dataset_id where source_dataset_id = :dup_dataset_id", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])
          execute sql_variable_inter_stringification("update imports set source_dataset_id = :original_dataset_id where source_dataset_id = :dup_dataset_id", :original_dataset_id => original_dataset_id, :dup_dataset_id => dup_dataset["id"])

          execute sql_variable_inter_stringification("delete from datasets where id = :dup_dataset_id", :dup_dataset_id => dup_dataset["id"])
        end

        execute sql_variable_inter_stringification("delete from schemas where id = :schema_id", :schema_id => old_schema_id)
      end

      execute sql_variable_inter_stringification("update schemas set active_tables_and_views_count = (select count(id) from datasets where schema_id = :schema_id and stale_at is null and type <> 'ChorusView')", :schema_id => original_schema_id)
    end
  end

  private

  def sql_variable_inter_stringification(sql, variables)
    sql.gsub /:\w+/ do |match|
      sym = match.sub(/^:/, '').to_sym
      variables.has_key?(sym) ? "'#{variables[sym]}'" : match
    end
  end
end
