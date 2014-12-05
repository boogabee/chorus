module Stale
  extend ActiveSupport::Concern

  included do
    scope :not_stale, where(:stale_at => nil)
  end

  def stale?
    stale_at.present?
  end

  def mark_stale!
    unless stale?
      self.stale_at = Time.now.utc
      save!(:validate => false)
    end
  end

  def mark_fresh!
    if stale?
      self.stale_at = nil
      save!(:validate => false)
    end
  end
end