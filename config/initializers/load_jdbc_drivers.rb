Dir[Rails.root.join('lib', 'libraries', '*.jar')].each do |filename|
   require filename
end