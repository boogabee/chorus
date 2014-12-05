class ActiveRecord::Base
  include ChorusApiValidationFormat
end

module ActiveRecord
  module Validations
    class AssociatedValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if Array.wrap(value).reject { |r| r.marked_for_destruction? || r.valid? }.any?
          value.errors.each do |attr, error|
            record.errors[options[:error_field] || attr] << error
          end
        end
      end
    end
  end
end