require 'presenter'

module CurrentUser
  extend ActiveSupport::Concern

  module ClassMethods
    def current_user
      Thread.current[:user]
    end
  end

  def current_user
    self.class.current_user
  end
end

class ActiveRecord::Base
  include CurrentUser
end

class Presenter
  include CurrentUser
end