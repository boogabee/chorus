module TaggableBehavior
  extend ActiveSupport::Concern

  included do
    has_many :taggings, :as => :taggable, :dependent => :destroy
    has_many :tags, :through => :taggings
  end

  module ClassMethods
    def taggable?
      true
    end
  end

  def tag_list=(tags_list)
    self.tags = tags_list.map do |tag_name|
      Tag.find_or_create_by_tag_name(tag_name)
    end
  end
end