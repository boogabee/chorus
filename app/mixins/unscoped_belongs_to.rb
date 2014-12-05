module UnscopedBelongsTo
  extend ActiveSupport::Concern

  module ClassMethods
    def unscoped_belongs_to(name, options = {})
      scoped_name = "scoped_#{name}".to_sym
      foreign_key = options[:foreign_key] || "#{name}_id".to_sym
      class_name  = options[:class_name] || name.to_s.camelize
      new_opts    = options.merge :foreign_key => foreign_key

      if options[:polymorphic]
        new_opts[:foreign_type] ||= "#{name}_type"
      else
        new_opts[:class_name] ||= class_name
      end

      belongs_to scoped_name, new_opts

      if options[:polymorphic]
        type_column = "#{name}_type".to_sym
        define_method(name) {
          type_value = send(type_column)
          return unless type_value
          unscoped_getter scoped_name, foreign_key, type_value
        }
      else
        define_method(name) { unscoped_getter scoped_name, foreign_key, class_name }
      end

      define_method("#{name}=".to_sym) { |value| send "#{scoped_name}=".to_sym, value }
    end
  end

  def unscoped_getter(scoped_name, foreign_key, class_name)
    value = send scoped_name
    unless value
      value = class_name.constantize.unscoped.find(send foreign_key)
      send "#{scoped_name}=", value
    end
    value
  rescue ActiveRecord::RecordNotFound
    nil
  end
end