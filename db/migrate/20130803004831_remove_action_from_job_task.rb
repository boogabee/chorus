class RemoveActionFromJobTask < ActiveRecord::Migration
  class MigrationJobTask < ActiveRecord::Base
    self.table_name = :job_tasks
  end

  def up
    remove_column :job_tasks, :action
  end

  def down
    add_column :job_tasks, :action, :string

    MigrationJobTask.all.each do |task|
      task.action = task.type.gsub(/Task\z/, '').underscore if task.type
      task.save
    end
  end
end
