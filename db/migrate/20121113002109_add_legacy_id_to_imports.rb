class AddLegacyIdToImports < ActiveRecord::Migration
  def change
    add_legacy_id :imports
  end

  def add_legacy_id(tablename)
    add_column tablename, :legacy_id, :string
  end
end
