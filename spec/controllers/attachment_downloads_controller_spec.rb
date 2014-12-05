require 'spec_helper'

describe AttachmentDownloadsController do

  let(:user) { users(:default) }

  before do
    log_in user
  end

  describe "#show" do
    let(:attachment) { attachments(:sql) }

    it "streams the file" do
      get :show, :attachment_id => attachment.to_param

      response.headers['Content-Disposition'].should include('attachment')
      response.headers['Content-Disposition'].should include('filename="workfile.sql"')
      response.headers['Content-Type'].should == 'application/octet-stream'
    end

    context 'when the user doesnt have permission' do
      let(:attachment) { attachments(:attachment_private_workspace) }

      it 'returns 403' do
        attachment = attachments(:attachment_private_workspace)
        get :show, :attachment_id => attachment.to_param

        response.should be_forbidden
      end
    end

  end
end
