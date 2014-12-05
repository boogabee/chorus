class AddWorkspaceIdToChorusViews < ActiveRecord::Migration
  def up
    add_column :datasets, :workspace_id, :integer
    update <<-SQL
      UPDATE datasets
        SET workspace_id = associated_datasets.workspace_id
        FROM associated_datasets
        WHERE datasets.type = 'ChorusView'
          AND associated_datasets.dataset_id = datasets.id
    SQL
    delete <<-SQL
      DELETE FROM associated_datasets
        USING datasets
        WHERE datasets.type = 'ChorusView'
          AND datasets.id = associated_datasets.dataset_id
    SQL
  end

  def down
    insert <<-SQL
      INSERT INTO associated_datasets (dataset_id, workspace_id, created_at, updated_at)
        SELECT id, workspace_id, now(), now()
        FROM datasets
        WHERE datasets.type = 'ChorusView'
    SQL
    remove_column :datasets, :workspace_id
  end
end
