module SoftDelete
  extend ActiveSupport::Concern

  included do
    default_scope :conditions => {:deleted_at => nil}
  end

  def destroy
    @being_destroyed = true
    run_callbacks(:destroy) do
      self.deleted_at = Time.current.utc
      save(:validate => false)
    end
    self
  end

  def deleted?
    deleted_at.present?
  end

  def being_destroyed?
    @being_destroyed
  end

  module ClassMethods
    def find_with_destroyed *args
      self.with_exclusive_scope { find(*args) }
    end
  end
end
