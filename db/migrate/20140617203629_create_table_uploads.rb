class CreateTableUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.references :user

      t.text :contents_file_name
      t.text :contents_content_type
      t.integer :contents_file_size
      t.datetime :contents_updated_at

      t.timestamps
    end
  end
end
