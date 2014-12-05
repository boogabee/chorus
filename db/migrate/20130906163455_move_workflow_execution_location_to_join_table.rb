class MoveWorkflowExecutionLocationToJoinTable < ActiveRecord::Migration

  class Workfile < ActiveRecord::Base
  end

  class WorkfileExecutionLocation < ActiveRecord::Base
    attr_accessible :workfile_id, :execution_location_id, :execution_location_type
  end

  def up
    puts "Migrating Execution Locations for... "
    Workfile.where(type: 'AlpineWorkfile').find_each do |workfile|
      puts " - ##{workfile.id}, #{workfile.file_name}"

      next unless workfile.execution_location_id

      WorkfileExecutionLocation.create!(
          :execution_location_id => workfile.execution_location_id,
          :execution_location_type => workfile.execution_location_type,
          :workfile_id => workfile.id
      )
      workfile.update_column(:execution_location_id, nil)
      workfile.update_column(:execution_location_type, nil)
    end
  end

  def down
    Workfile.find_each do |workfile|
      join_record = WorkfileExecutionLocation.where(:workfile_id => workfile.id).first

      if join_record.present?
        workfile.update_column(:execution_location_id, join_record.execution_location_id)
        workfile.update_column(:execution_location_type, join_record.execution_location_type)
      end
    end

    WorkfileExecutionLocation.destroy_all
  end
end
