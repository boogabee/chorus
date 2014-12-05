class DataSourceAccount < ActiveRecord::Base

  attr_accessible :db_username, :db_password, :owner
  validate :credentials_are_valid
  validates_presence_of :db_username, :db_password, :data_source, :owner
  validates_uniqueness_of :owner_id, :scope => :data_source_id

  attr_encrypted :db_password, :encryptor => ChorusEncryptor, :encrypt_method => :encrypt_password, :decrypt_method => :decrypt_password, :encode => false

  has_many :data_source_account_permissions, :dependent => :destroy
  has_many :accesseds, :through => :data_source_account_permissions
  # has_many :gpdb_databases, :through => :data_source_account_permissions, :source => :accessed,
  #          :conditions => "data_source_account_permissions.accessed_type = 'GpdbDatabase'"

  belongs_to :owner, :class_name => 'User'
  belongs_to :data_source

  after_save :reindex_data_source
  after_destroy :reindex_data_source
  after_destroy { data_source_account_permissions.clear }

  def reindex_data_source
    data_source.refresh_databases_later
  end

  def invalid_credentials!
    return if @currently_validating_creds
    with_lock do
      return if invalid_credentials?
      self.invalid_credentials = true
      save(:validate => false)
      event = Events::CredentialsInvalid.by(owner).add(:data_source => data_source)
      Notification.create!(:event => event, :recipient => owner)
    end
  end

  private

  def credentials_are_valid
    @currently_validating_creds = true
    self.invalid_credentials = false
    association = association(:data_source)
    if association.loaded?
      association.loaded! if association.stale_target?
    end
    return unless data_source && db_username.present? && db_password.present?
    check_hawq = data_source.is_hawq
    unless data_source.valid_db_credentials?(self)
      check_hawq = false
      errors.add(:base, :INVALID_PASSWORD)
    end
    if check_hawq
      unless data_source.is_hawq_data_source?(self)
        errors.add(:base, :INVALID_HAWQ_DATA_SOURCE)
      end
    end
  ensure
    @currently_validating_creds = false
  end
end
