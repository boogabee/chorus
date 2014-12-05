class Import < ActiveRecord::Base
  include ImportMixins

  attr_accessible :to_table, :new_table, :sample_count, :truncate, :user
  attr_accessible :file_name # only for CSV files

  belongs_to :source, :polymorphic => true
  belongs_to :user

  validates :to_table, :presence => true
  validates :user, :presence => true

  validate :table_does_not_exist, :if => :new_table, :on => :create
  validates :scoped_source, :presence => true, :unless => :file_name
  validates :file_name, :presence => true, :unless => :scoped_source
  validate :tables_have_consistent_schema, :unless => :file_name, :on => :create
  validates_numericality_of :sample_count, :only_integer => true, :less_than_or_equal_to => 2147483647, :allow_blank => true

  after_create :create_import_event

  alias_method :scoped_source, :source

  def source
    value = scoped_source
    unless value
      value = self.source = source_type.constantize.unscoped.find(source_id)
    end
    value
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.unfinished
    where(:finished_at => nil)
  end

  def create_import_event
    raise "implement me!"
  end

  def copier_class
    raise "implement me!"
  end

  def mark_as_success
    set_destination_dataset_id
    save(:validate => false)
    create_passed_event_and_notification
    update_import_created_event
  end

  def runnable?
    success.nil? && !canceled?
  end

  def canceled?
    canceled_at?
  end

  def workspace_import?
    self.is_a?(WorkspaceImport)
  end

  def handle
    "#{created_at.to_i}_#{id}"
  end

  def update_status(status, message = nil)
    return unless success.nil?

    passed = (status == :passed)

    touch(:finished_at)
    update_attribute(:success, passed)

    if passed
      index_destination_dataset
      mark_as_success
    else
      create_failed_event_and_notification(message)
    end
  end

  def cancel(success, message = nil)
    begin
      log "Terminating import: #{inspect}"
      copier_class.cancel(self)
    rescue => e
      log "Error canceling import, #{e.inspect}"
      log "Stack = #{e.backtrace}"
    end
    update_status(success ? :passed : :failed, message)
  end

  def enqueue_import
    QC.enqueue_if_not_queued("ImportExecutor.run", id)
  end

  def validate_source!
    raise "Original source dataset #{source.scoped_name} has been deleted" if source.deleted?
  end

  def mark_as_canceled!(message)
    touch(:canceled_at)
    self.cancel_message = message
    save!
  end

  def named_pipe
    return @named_pipe if @named_pipe
    return unless ChorusConfig.instance.gpfdist_configured?
    dir = Pathname.new ChorusConfig.instance['gpfdist.data_dir']
    @named_pipe = Dir.glob(dir.join "pipe*_#{handle}").first
  end

  private

  def log(message)
    Rails.logger.info("Import Termination: #{message}")
  end

  def update_import_created_event
    event = created_event_class.find_for_import(self)

    if event
      event.dataset = find_destination_dataset
      event.save!
    end
  end

  def index_destination_dataset
    # update rails db for new dataset
    schema.find_or_initialize_dataset(to_table).save
  end
end