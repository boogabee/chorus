require 'spec_helper'

describe WorkfileVersionsController do
  ignore_authorization!
  let(:workfile) { workfiles(:public) }
  let(:workspace) { workfile.workspace }
  let(:user) { workspace.owner }
  let(:workfile_version) { workfile_versions(:public) }

  before do
    log_in user
  end

  describe "#update" do
    let(:params) { {:workfile_id => workfile.id, :id => workfile_version.id, :content => 'New content'} }
    before do
      workfile_version.contents = test_file('workfile.sql')
      workfile_version.save
    end

    it "changes the file content" do
      put :update, params

      File.read(workfile.latest_workfile_version.contents.path).should == 'New content'
    end

    it "deletes any saved workfile drafts for this workfile and user" do
      any_instance_of(workfile.class) do |workfile|
        mock(workfile).remove_draft(user)
      end

      put :update, params
    end

    context "when the workfile version does not exist" do
      it "should return a 404 error" do
        put :update, params.merge(:id => -1)
        response.code.should == "404"
      end
    end

    it "presents the workfile version with the content" do
      mock_present do |model, ignored, options|
        model.should == workfile_version
        options[:contents].should be_true
      end

      put :update, params
      response.code.should == "200"
    end
  end

  describe "#create" do
    let(:params) { {:workfile_id => workfile.id, :content => 'New content', :commit_message => 'A new version'} }

    before do
      any_instance_of(workfile.class) do |workfile|
        mock(workfile).create_new_version(user, hash_including(:content => 'New content', :commit_message => 'A new version'))
      end
      workfile_version.contents = test_file('workfile.sql')
      workfile_version.save
    end

    it "presents the workfile version with the content" do
      mock_present do |model, ignored, options|
        model.should == workfile.reload.latest_workfile_version
        options[:contents].should be_true
      end

      post :create, params
      response.code.should == "201"
    end
  end

  context "#show" do
    before do
      workfile_version.contents = test_file('workfile.sql')
      workfile_version.save
    end

    let(:params) { { :workfile_id => workfile.id, :id => workfile_version.id } }

    it "show the specific version for the workfile" do
      another_version = workfile.build_new_version(user, test_file('some.txt'), "commit message - 1")
      another_version.save

      get :show, params

      decoded_response[:version_info][:version_num].should == 1
      decoded_response[:version_info][:version_num].should_not == another_version.version_num
      decoded_response[:version_info][:content].should_not be_nil
    end

    it "presents the workfile version with the content" do
      mock_present do |model, ignored, options|
        model.should == workfile_version
        options[:contents].should be_true
      end

      get :show, params

      response.code.should == "200"
    end

    generate_fixture "workfileVersion.json" do
      get :show, params
    end
  end

  describe "#index" do
    let(:workspace) { workspaces(:public) }
    let(:workfile) { workfiles(:public) }

    before :each do
      workfile_version.save
      workfile.build_new_version(user, test_file('some.txt'), "commit message - 2").save
      workfile.build_new_version(user, test_file('some.txt'), "commit message - 3").save
    end

    it "returns the index of all the workfile versions" do
      get :index, :workfile_id => workfile.id

      decoded_response.length.should == 3
      decoded_response[0].version_num = 3
      decoded_response[1].version_num = 2
    end

    generate_fixture "workfileVersionSet.json" do
      get :index, :workfile_id => workfile.id
    end

    it_behaves_like "a paginated list" do
      let(:params) {{ :workfile_id => workfile.to_param }}
    end
  end

  describe "#destroy" do
    let(:workspace) { workspaces(:public) }
    let(:workfile) { workfiles(:public) }

    context "when there's more than one versions" do
      before do
        workfile.reload.build_new_version(user, test_file('some.txt'), "commit message - 2").save
        workfile.reload.build_new_version(user, test_file('some.txt'), "commit message - 3").save
        workfile.reload.build_new_version(user, test_file('some.txt'), "commit message - 4").save
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        delete :destroy, :workfile_id => workfile.id, :id => workfile.versions[2].id
      end

      it "should deletes the version" do
        delete :destroy, :workfile_id => workfile.id, :id => workfile.versions[2].id
        workfile.reload.versions.length.should == 3
      end

      it "should respond with success" do
        response.should be_success
      end

      context "deleting the last version" do
        before do
          delete :destroy, :workfile_id => workfile.id, :id => workfile.versions[0].id
        end

        it "should updates the lastest_version_id of the workfile" do
          workfile.reload.latest_workfile_version_id.should == workfile.reload.versions[0].id
        end

        it "should deletes the version" do
          workfile.reload.versions.length.should == 3
        end
      end
    end

    context "when there's only one version" do
      it "raises an error" do
        delete :destroy, :workfile_id => workfile.id, :id => workfile.versions[0].id

        response.code.should == "422"
        response.body.should include "ONLY_ONE_VERSION"
      end
    end
  end
end
