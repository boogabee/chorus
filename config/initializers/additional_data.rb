require 'json'

class ActiveRecord::Base
  def self.has_additional_data(*names)
    attr_accessible(*names, :as => [:default, :create])
    names.each do |name|
      define_method(name) { additional_data[name.to_s] }
      define_method("#{name}=") { |value| additional_data[name.to_s] = value }
    end
  end
end