module ActiveRecord
  class Base
    def self.taggable?
      false
    end
  end
end