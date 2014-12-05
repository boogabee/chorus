module CommonDataSourceBehavior
  extend ActiveSupport::Concern

  included do
    attr_accessor :highlighted_attributes, :search_result_notes
    searchable_model do
      text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
      text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    end

    def self.type_name
      'DataSource'
    end

    validates_with DataSourceTypeValidator
  end

  def check_status!
    update_state_and_version

    touch(:last_checked_at)
    touch(:last_online_at) if online?
    save!
  end

  def license_type
    type
  end

  def online?
    state == 'online'
  end

  def attempt_connection(user)
  end
end
