require 'spec_helper'

describe DataSources::OwnersController do
  let(:data_source) { data_sources(:shared) }
  let(:user) { data_source.owner }
  let(:new_owner) { users(:no_collaborators) }

  ignore_authorization!

  before do
    log_in user
  end

  describe "#update" do
    def request_ownership_update
      put :update, :data_source_id => data_source.to_param, :owner => {:id => new_owner.to_param }
    end

    it "uses authorization" do
      mock(controller).authorize!(:edit, data_source)
      request_ownership_update
    end

    context "with a greenplum data source" do
      it "switches ownership of data source and account" do
        mock(DataSourceOwnership).change(user, data_source, new_owner)
        request_ownership_update
      end

      it "presents the data source" do
        stub(DataSourceOwnership).change(user, data_source, new_owner)
        mock_present { |data_source_presented| data_source_presented.should == data_source }
        request_ownership_update
      end
    end

    context "with an oracle data source" do
      let(:data_source) { data_sources(:oracle) }

      it "switches ownership of data source and account" do
        mock(DataSourceOwnership).change(user, data_source, new_owner)
        request_ownership_update
      end

      it "presents the data source" do
        stub(DataSourceOwnership).change(user, data_source, new_owner)
        mock_present { |data_source_presented| data_source_presented.should == data_source }
        request_ownership_update
      end
    end
  end
end
