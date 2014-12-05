class GpdbSchema < Schema
  include SandboxSchema

  has_many :views, :source => :datasets, :class_name => 'GpdbView', :foreign_key => :schema_id
  has_many :tables, :source => :datasets, :class_name => 'GpdbTable', :foreign_key => :schema_id

  validates :name, :format => /^[^\/?&]*$/

  before_save :mark_schemas_as_stale

  def class_for_type(type)
    type == 'r' ? GpdbTable : GpdbView
  end

  private

  def mark_schemas_as_stale
    if stale? && stale_at_changed?
      datasets.each do |dataset|
        dataset.mark_stale! unless dataset.type == "ChorusView"
      end
    end
  end
end
