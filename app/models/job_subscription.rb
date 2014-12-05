class JobSubscription < ActiveRecord::Base
  attr_accessible :user, :condition

  belongs_to :user
  belongs_to :job
end