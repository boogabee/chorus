RSpec::Matchers.define :validate_with do |validator|
  match do |subject|
    any_instance_of(validator) do |v|
      mock(v).validate(subject).at_least(1) { true }
    end
    subject.valid?
    true
  end
end
