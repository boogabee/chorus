class SetTruncateOnImportSourceDataToBoolean < ActiveRecord::Migration
  def up
    job_tasks = select_all "select id, additional_data from job_tasks"
    job_tasks.each do |task|
      additional_data = JSON.parse(task['additional_data'])
      additional_data['truncate'] = false

      execute("update job_tasks set additional_data = '#{JSON.unparse(additional_data)}' where id = #{task['id']}")
    end
  end

  def down
  end
end
