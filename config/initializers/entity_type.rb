module ActiveRecord
  class Base
    def entity_type_name
      self.class.name.underscore
    end

    def entity_subtype
      nil
    end
  end
end