require "spec_helper"

describe DataSourceOwnership do
  let!(:old_owner) { gpdb_data_source.owner }
  let!(:owner_account) { gpdb_data_source.owner_account }
  let!(:new_owner) { FactoryGirl.create(:user) }

  describe ".change_owner(data_source, new_owner)" do
    let(:gpdb_data_source) { FactoryGirl.create(:gpdb_data_source, :shared => true) }
    before do
      stub(gpdb_data_source).valid_db_credentials? { true }
    end

    it "creates a DataSourceChangedOwner event" do
      request_ownership_update
      event = Events::DataSourceChangedOwner.by(old_owner).last
      event.data_source.should == gpdb_data_source
      event.new_owner.should == new_owner
    end

    context "with a shared gpdb data_source" do
      it "switches ownership of gpdb data source and account" do
        request_ownership_update
        gpdb_data_source.owner.should == new_owner
        owner_account.owner.should == new_owner
      end
    end

    context "with an unshared data source" do
      let(:gpdb_data_source) { FactoryGirl.create(:gpdb_data_source, :shared => false) }

      context "when switching to a user with an existing account" do
        before do
          FactoryGirl.build(:data_source_account, :data_source => gpdb_data_source, :owner => new_owner).tap { |a| a.save(:validate => false)}
        end

        it "switches ownership of data source" do
          request_ownership_update
          gpdb_data_source.owner.should == new_owner
        end

        it "keeps ownership of account" do
          request_ownership_update
          owner_account.owner.should == old_owner
        end
      end

      context "when switching to a user without an existing account" do
        it "complains" do
          expect {
            request_ownership_update
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  def request_ownership_update
    DataSourceOwnership.change(old_owner, gpdb_data_source, new_owner)
    gpdb_data_source.reload
    owner_account.reload
  end
end
