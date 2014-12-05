RSpec::Matchers.define :be_forbidden_by_license do
  match do |actual|
    actual.should be_forbidden
    actual.decoded_body.try(:errors).license.should == 'NOT_LICENSED'
  end

  failure_message_for_should do |actual|
    %(expected that status/errors would be 403/{:license => 'NOT_LICENSED'} but \
was #{actual.status}/#{actual.decoded_body.try(:errors)})
  end
end
