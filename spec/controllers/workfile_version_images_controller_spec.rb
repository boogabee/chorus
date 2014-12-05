require 'spec_helper'

describe WorkfileVersionImagesController do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:public) }
  let(:version) { workfile_versions(:public) }

  before do
    log_in user
  end

  describe "#show" do
    before do
      version.contents = test_file('small1.gif')
      version.save
    end

    it "returns the file" do
      get :show, :workfile_version_id => version.id
      response.content_type.should == "image/gif"
    end

    it "uses authorization" do
      mock(subject).authorize! :show, workfile.workspace
      get :show, :workfile_version_id => version.id
    end

    context "when the file is missing" do
      before do
        FileUtils.rm version.contents.path
      end

      it "returns 404" do
        get :show, :workfile_version_id => version.id
        response.code.should == "404"
      end
    end
  end
end