class CreateNotesWorkflowResultsTable < ActiveRecord::Migration
  def change
    create_table :notes_work_flow_results do |t|
      t.integer :result_id
      t.integer :note_id
    end
  end
end
