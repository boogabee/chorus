require 'spec_helper'

describe AlpineWorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:'alpine_flow') }
  let(:options) { {} }
  let(:presenter) { AlpineWorkfilePresenter.new(workfile, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    describe "when the 'workfile_as_latest_version' option is set" do
      let(:options) { {:workfile_as_latest_version => true} }

      it "creates a version_info hash that includes the created and updated time of the workfile" do
        hash[:version_info].should == {:created_at => workfile.created_at, :updated_at => workfile.updated_at}
      end
    end

    describe "execution locations" do
      context "when presenting for a 'show' view" do
        it "presents execution location" do
          hash[:execution_locations].should == workfile.execution_locations.map { |loc| Presenter.present(loc, view, :succinct => true) }
        end
      end

      context "when presenting for a list_view" do
        let(:options) { {:list_view => true} }
        let(:workfile) { workfiles("alpine_flow") }

        it "does not present the execution location" do
          hash.should_not have_key(:execution_locations)
          hash.should_not have_key(:dataset_ids)
        end
      end
    end

    describe 'datasets' do
      let(:workfile) { workfiles(:multiple_dataset_workflow) }
      it 'presents the dataset ids' do
        hash.should have_key(:dataset_ids)
      end
    end
  end
end
