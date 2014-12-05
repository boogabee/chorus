class RenameNoteOnGreenplumInstanceToNoteOnDataSource < ActiveRecord::Migration
  def up
    execute "UPDATE events SET action='Events::NoteOnDataSource' WHERE action='Events::NoteOnGreenplumInstance'"
  end

  def down
    execute "UPDATE events SET action='Events::NoteOnGreenplumInstance' WHERE action='Events::NoteOnDataSource'"
  end
end
