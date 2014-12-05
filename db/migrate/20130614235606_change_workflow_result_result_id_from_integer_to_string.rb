class ChangeWorkflowResultResultIdFromIntegerToString < ActiveRecord::Migration
  def change
    change_column :notes_work_flow_results, :result_id, :string
  end
end
