RSpec::Matchers.define :be_sorted_by do |attribute, downcase = false|
  match do |list|
    attributes = list.map(&attribute)
    attributes = attributes.map(&:downcase) if downcase
    attributes.should == attributes.sort
  end

  description do |list|
    "#{list.inspect} to be sorted by '#{attribute.to_s}'"
  end
end