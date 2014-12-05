class RenameDatasetImportEvents < ActiveRecord::Migration
    def up
      execute("UPDATE events SET action = 'Events::WorkspaceImportCreated' WHERE action = 'Events::DatasetImportCreated';")
      execute("UPDATE events SET action = 'Events::WorkspaceImportSuccess' WHERE action = 'Events::DatasetImportSuccess';")
      execute("UPDATE events SET action = 'Events::WorkspaceImportFailed' WHERE action = 'Events::DatasetImportFailed';")
    end
    def down
      execute("UPDATE events SET action = 'Events::DatasetImportFailed' WHERE action = 'Events::WorkspaceImportFailed';")
      execute("UPDATE events SET action = 'Events::DatasetImportSuccess' WHERE action = 'Events::WorkspaceImportSuccess';")
      execute("UPDATE events SET action = 'Events::DatasetImportCreated' WHERE action = 'Events::WorkspaceImportCreated';")
    end
end
