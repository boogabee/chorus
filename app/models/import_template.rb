class ImportTemplate < ActiveRecord::Base
  attr_accessible :destination_id, :destination_name, :row_limit, :source_id, :truncate
  belongs_to :source, :class_name => 'Dataset'
  belongs_to :destination, :class_name => 'Dataset'
  has_one :import_source_data_task, :foreign_key => :payload_id

  delegate :workspace, :to => :import_source_data_task
  delegate :job, :to => :import_source_data_task

  before_save :update_destination_name, :if => Proc.new { |job| job.changed.include?('destination_id') }
  before_save :update_destination_id, :if => Proc.new { |job| job.changed.include?('destination_name') }

  def new_table_import?
    !destination_id
  end

  def set_destination_id!
    self.destination_id = import_created_table.id
    self.destination_name = nil
    save!
  end

  def import_created_table
    workspace.sandbox.datasets.find_by_name(destination_name)
  end

  def create_import
    import_params = {
        :user => job.owner,
        :to_table => destination_name || destination.name,
        :truncate => truncate,
        :sample_count => row_limit,
        :new_table => new_table_import?
    }
    import = WorkspaceImport.new(import_params)
    import.workspace = workspace
    import.source_dataset = source
    import.save!
    import
  end

  private

  def update_destination_name
    self.destination_name = nil if destination
  end

  def update_destination_id
    self.destination_id = nil if destination_name
  end
end
