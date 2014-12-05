require 'spec_helper'

describe DataSourceAuth do
  include DataSourceAuth

  describe '#account_for_current_user' do
    let(:current_user) {  users(:owner) }

    context "when the resource's data_source has no account_for_user" do
      let(:resource) { datasets(:hadoop) }

      it 'returns nil' do
        account_for_current_user(resource).should be_nil
      end
    end

    context "when the resource's data_source has an account_for_user" do
      let(:resource) { datasets(:table) }

      it 'returns the account' do
        account_for_current_user(resource).should == resource.data_source.account_for_user!(current_user)
      end
    end
  end
end