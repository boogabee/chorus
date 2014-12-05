require 'dataset'

class GpdbView < GpdbDataset
  attr_accessible :query

  def verify_in_source(user)
    schema.verify_in_source(user) &&
    schema.connect_as(user).view_exists?(name)
  end
end