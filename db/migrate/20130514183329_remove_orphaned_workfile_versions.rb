class RemoveOrphanedWorkfileVersions < ActiveRecord::Migration
  class MigrationWorkfileVersion < ActiveRecord::Base
    self.table_name = :workfile_versions

    has_attached_file :contents,
                      :styles => {:icon => "50x50>"},
                      :path => ":rails_root/system/:class/:id/:style/:basename.:extension",
                      :url => "/:class/:id/image?style=:style",
                      :restricted_characters => nil
  end

  def up
    MigrationWorkfileVersion.where("workfile_id NOT IN (SELECT id FROM workfiles WHERE deleted_at IS NULL)").find_each do |workfile_version|
      workfile_version.destroy
    end
  end
end
