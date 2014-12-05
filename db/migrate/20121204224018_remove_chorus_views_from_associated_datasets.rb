class RemoveChorusViewsFromAssociatedDatasets < ActiveRecord::Migration
  def change
    Workspace.unscoped.all.each do |workspace|
      AssociatedDataset.unscoped do
        workspace.associated_datasets.all.each do |association|
          Dataset.unscoped do
            workspace.associated_datasets.delete(association) if association.dataset.is_a?(ChorusView)
          end
        end
      end
    end
  end
end