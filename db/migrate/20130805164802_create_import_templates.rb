class CreateImportTemplates < ActiveRecord::Migration
  def change
    create_table :import_templates do |t|
      t.integer :destination_id
      t.integer :source_id
      t.string :destination_name
      t.boolean :truncate
      t.integer :row_limit

      t.timestamps
    end
  end
end
