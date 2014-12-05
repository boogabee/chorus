class AddReferenceIdToEvents < ActiveRecord::Migration
  def change
    # Initially this is always an Import because imports are the only thing
    # that need to mutate Events after they are done, to update the destination dataset id.
    add_column :events, :reference_id, :integer
  end
end
