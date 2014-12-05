class NotesWorkFlowResult < ActiveRecord::Base
  belongs_to :event, :class_name => 'Events::Base', :foreign_key => 'note_id'
  attr_accessible :result_id
end
