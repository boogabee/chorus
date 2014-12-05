class AssociatedDataset < ActiveRecord::Base
  include SoftDelete

  validates_presence_of :workspace, :dataset
  validate :datasets_in_association_are_unique, :on => :create
  validate :dataset_not_chorus_view
  validate :ensure_active_workspace

  belongs_to :workspace
  belongs_to :dataset

  private

  def dataset_not_chorus_view
    if dataset.is_a? ChorusView
      errors.add(:dataset, :invalid_type)
    end
  end

  def datasets_in_association_are_unique
    if workspace && workspace.has_dataset?(dataset)
      errors.add(:dataset, :already_associated, { :workspace_name => workspace.name})
    end
  end

  def ensure_active_workspace
    self.errors[:dataset] << :ARCHIVED if workspace && workspace.archived?
  end
end
