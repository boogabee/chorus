class GpdbDatabase < Database

  has_many :schemas, :class_name => 'GpdbSchema', :as => :parent, :dependent => :destroy
  has_many :datasets, :through => :schemas

end
