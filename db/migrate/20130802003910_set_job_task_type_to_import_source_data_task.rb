class SetJobTaskTypeToImportSourceDataTask < ActiveRecord::Migration
  def up
    execute("UPDATE job_tasks SET type = 'ImportSourceDataTask'")
  end
end
