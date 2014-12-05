require "spec_helper"

describe Notification do
  it { should validate_presence_of :recipient_id }
  it { should validate_presence_of :event_id }

  it_behaves_like 'a soft deletable model' do
    let(:model) { notifications(:notification1) }
  end
end
