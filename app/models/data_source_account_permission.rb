class DataSourceAccountPermission < ActiveRecord::Base
  belongs_to :data_source_account
  belongs_to :accessed, polymorphic: true

  validate :accessed, presence: true
  validate :data_source_account, presence: true
end