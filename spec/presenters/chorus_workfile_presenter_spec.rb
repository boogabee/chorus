require 'spec_helper'

describe ChorusWorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:private) }
  let(:workspace) { workfile.workspace }
  let(:options) { {} }
  let(:presenter) { ChorusWorkfilePresenter.new(workfile, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:latest_version_id)
      hash.should have_key(:has_draft)

      hash.should_not have_key(:execution_schema)
    end

    context "workfile has a draft for that user" do
      it "has_draft value is true" do
        FactoryGirl.create(:workfile_draft, :workfile_id => workfile.id, :owner_id => user.id)
        hash = presenter.to_hash
        hash[:has_draft].should == true
      end
    end

    context "No workfile draft for that user" do
      it "has_draft value is false" do
        hash[:has_draft].should == false
      end
    end

    context ":include_execution_schema is passed as an option" do
      let(:options) { {:include_execution_schema => true} }

      it "includes the execution_schema" do
        hash[:execution_schema].should == GpdbSchemaPresenter.new(workfile.execution_schema, view).presentation_hash
      end
    end

    context "for activity stream" do
      let(:options) { {:activity_stream => true} }

      it "should not include owner or draft status" do
        hash[:owner].should be_nil
        hash[:has_draft].should be_nil
      end
    end

    context "for list view" do
      let(:options) { {:list_view => true} }

      it "should not draft status" do
        hash[:has_draft].should be_nil
      end

      context "when also presenting the execution schema" do
        let(:options) { {:list_view => true, :include_execution_schema => true} }

        it "should present the execution schema succinctly" do
          hash[:execution_schema].should == GpdbSchemaPresenter.new(workfile.execution_schema, view, :succinct => true).presentation_hash
        end
      end
    end

    describe "when the 'workfile_as_latest_version' option is set" do
      let(:options) { {:workfile_as_latest_version => true} }

      it "calls the presenter for the latest version of the workfile" do
        mock(ChorusWorkfilePresenter).present(workfile.latest_workfile_version, anything, {})
        hash
      end

      context "when there is no latest workfile version" do
        before do
          workfile.latest_workfile_version_id = nil
        end

        it "does not try to present the latest workfile version" do
          dont_allow(Presenter).present
          hash
        end
      end
    end
  end

  describe "complete_json?" do
    context "when not including execution schema" do
      it "is not true" do
        presenter.complete_json?.should_not be_true
      end
    end

    context "when including execution schema" do
      let(:options) { {:include_execution_schema => true, :activity_stream => activity_stream} }

      context "when rendering activity stream" do
        let(:activity_stream) { true }
        it "should be false" do
          presenter.should_not be_complete_json
        end
      end

      context "when not rendering for activity stream" do
        let(:activity_stream) { false }
        it "is true" do
          presenter.complete_json?.should be_true
        end
      end
    end
  end
end
