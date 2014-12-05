require 'spec_helper'

describe WorkfileDraftController do
  let(:workspace) { workspaces(:private) }
  let(:user) { users(:owner) }
  let(:workfile) { FactoryGirl.create(:workfile, :file_name => "workfile.txt",
                                      :owner => user, :workspace => workspace) }
  let(:valid_attributes) { { :content => "Valid content goes here", :workfile_id => workfile.id } }
  let!(:draft) do
    workfile_drafts(:draft_default).tap do |draft|
      draft.content = "Valid content goes here"
      draft.owner_id = user.id
      draft.workfile_id = workfile.id
    end
  end

  before(:each) do
    log_in user
  end

  describe "#create" do
    context "with valid attributes" do
      it "should save the data" do
        post :create, valid_attributes
        response.code.should == "201"
      end

      it "renders the newly created draft" do
        post :create, valid_attributes
        decoded_response.content.should == "Valid content goes here"
        decoded_response.workfile_id.should == workfile.id
        decoded_response.owner_id.should == user.id
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workfile.workspace
        post :create, valid_attributes
      end
    end
  end

  describe "#show" do
    before do
      draft.save!
    end
    it "renders the specified draft" do
      get :show, :workfile_id => workfile.id
      decoded_response.content.should == "Valid content goes here"
      decoded_response.workfile_id.should == workfile.id
      decoded_response.owner_id.should == user.id
      decoded_response.id.should == draft.id
    end

    it "uses authorization" do
      mock(subject).authorize! :show, workfile.workspace
      get :show, :workfile_id => workfile.id
    end

    generate_fixture "draft.json" do
      get :show, :workfile_id => workfile.id
    end
  end

  describe "#update" do
    before do
      draft.save!
    end
    it "updates and renders the updated values" do
      put :update, :content => "I am a leaf upon the wind, watch how I soar.", :workfile_id => workfile.id
      decoded_response.content.should == "I am a leaf upon the wind, watch how I soar."
      decoded_response.workfile_id.should == workfile.id
      decoded_response.owner_id.should == user.id
      decoded_response.id.should == draft.id
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workfile.workspace
      put :update, :content => "I am a leaf upon the wind, watch how I soar.", :workfile_id => workfile.id
    end
  end

  describe "#delete" do
    it "deletes the draft" do
      draft.save!
      delete :destroy, :workfile_id => workfile.id
      response.should be_success
    end

    it "does not delete anything if given a non-existing draft" do
      lambda { delete :destroy, :workfile_id => workfile.id }.should_not change { WorkfileDraft.count }
      response.code.should == '404'
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workfile.workspace
      delete :destroy, :workfile_id => workfile.id
    end
  end
end