class CreateHdfsImports < ActiveRecord::Migration
  def change
    create_table :hdfs_imports do |t|
      t.references :hdfs_entry
      t.references :user
      t.references :upload

      t.string :file_name
      t.boolean :success
      t.datetime :finished_at

      t.timestamps
    end
  end
end
