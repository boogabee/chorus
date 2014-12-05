class Attachment < ActiveRecord::Base
  include SharedSearch

  attr_accessible :contents

  has_attached_file :contents,
                    :path => ":rails_root/system/:class/:id/:style/:basename.:extension",
                    :url => "/notes/:note_id/attachments/:id?style=:style",
                    :styles => {:original => "", :icon => "50x50>" }

  before_post_process :contents_are_image?

  belongs_to :note, :class_name => 'Events::Base', :conditions => "events.action ILIKE 'Events::Note%'"

  validates_attachment_size :contents, :less_than => ChorusConfig.instance['file_sizes_mb']['attachment'].megabytes, :message => :file_size_exceeded

  attr_accessor :highlighted_attributes, :search_result_notes
  searchable_model do
    text :name, :stored => true, :using => :contents_file_name, :boost => SOLR_PRIMARY_FIELD_BOOST
  end

  delegate_search_permissions_for :workspace, :dataset, :to => :note

  def contents_are_image?
    MIME::Types.type_for(contents_file_name).first.to_s.starts_with?('image/')
  end
end
