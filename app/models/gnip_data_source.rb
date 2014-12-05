class GnipDataSource < ActiveRecord::Base
  include TaggableBehavior
  include Notable
  include SoftDelete

  attr_accessible :name, :stream_url, :description, :username, :password, :owner
  attr_accessor :highlighted_attributes, :search_result_notes

  after_destroy :create_deleted_event, :if => :current_user

  validates_presence_of :name, :stream_url, :username, :password, :owner
  validates_length_of :name, :maximum => 64

  validates_with DataSourceNameValidator
  validates_with DataSourceTypeValidator

  belongs_to :owner, :class_name => 'User'
  has_many :events, :through => :activities
  has_many :activities, :as => :entity

  searchable_model do
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
  end

  def self.type_name
    'DataSource'
  end

  def license_type
    self.class.name
  end

  private

  def create_deleted_event
    Events::DataSourceDeleted.by(current_user).add(:data_source => self)
  end
end
