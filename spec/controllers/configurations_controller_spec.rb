require 'spec_helper'

describe ConfigurationsController do
  describe "#show" do
    before do
      @user = users(:no_collaborators)
      log_in @user
      mock(LdapClient).enabled? { true }
      stub(File).directory? { true }
      stub.proxy(ChorusConfig.instance).[](anything)
      stub.proxy(License.instance).[](anything)
    end

    it "includes the ldap status" do
      stub(ChorusConfig.instance).[]('ldap') { {'enabled' => true} }
      get :show
      response.code.should == "200"
      decoded_response.external_auth_enabled.should == true
    end

    it "includes the tableau_configured? value" do
      stub(ChorusConfig.instance).tableau_configured? { 'value' }
      get :show
      response.code.should == "200"
      decoded_response.tableau_configured.should == 'value'
    end

    it "includes the kaggle_configured? value" do
      stub(ChorusConfig.instance).kaggle_configured? { 'value' }
      get :show
      response.code.should == "200"
      decoded_response.kaggle_configured.should == 'value'
    end

    it "includes the gnip_configured? value" do
      stub(ChorusConfig.instance).gnip_configured? { 'value' }
      get :show
      response.code.should == "200"
      decoded_response.gnip_configured.should == 'value'
    end

    it "includes the oracle_configured? value" do
      stub(ChorusConfig.instance).oracle_configured? { 'truthy' }
      get :show
      response.code.should == "200"
      decoded_response.oracle_configured.should == 'truthy'
    end

    it "gpfdist_configured is true when config.gpfdist_configured? is true" do
      stub(ChorusConfig.instance).gpfdist_configured? { true }
      get :show
      response.code.should == "200"
      decoded_response.gpfdist_configured.should == true
    end

    it "gpfdist_configured is false when config.gpfdist_configured? is false" do
      stub(ChorusConfig.instance).gpfdist_configured? { false }
      get :show
      response.code.should == "200"
      decoded_response.gpfdist_configured.should == false
    end

    it "includes the default preview row limits" do
      stub(ChorusConfig.instance).[]('default_preview_row_limit') { 12 }
      get :show
      response.code.should == "200"
      decoded_response.default_preview_row_limit.should == 12
    end

    it "includes the execution timeout" do
      stub(ChorusConfig.instance).[]('execution_timeout_in_minutes') { 3 }
      get :show
      response.code.should == "200"
      decoded_response.execution_timeout_in_minutes.should == 3
    end

    it "includes the file size maximums" do
      stub(ChorusConfig.instance).[]('file_sizes_mb.csv_imports') { 1 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.workfiles') { 10 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.user_icon') { 5 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.workspace_icon') { 5 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.attachment') { 10 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.hd_upload') { 4096 }
      get :show
      response.code.should == "200"
      decoded_response.file_sizes_mb_csv_imports.should == 1
      decoded_response.file_sizes_mb_workfiles.should == 10
      decoded_response.file_sizes_mb_user_icon.should == 5
      decoded_response.file_sizes_mb_workspace_icon.should == 5
      decoded_response.file_sizes_mb_attachment.should == 10
      decoded_response.file_sizes_mb_hd_upload.should == 4096
    end

    it "includes the visualization overlay string" do
      stub(ChorusConfig.instance).[]('visualization.overlay_string') { 'FOR OFFICIAL USE ONLY'*50 }
      get :show

      response.code.should == "200"
      decoded_response.visualization_overlay_string.should == ('FOR OFFICIAL USE ONLY'*50)[0...40]
    end

    generate_fixture "config.json" do
      stub(ChorusConfig.instance).[]('file_sizes_mb.csv_imports') { 1 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.workfiles') { 10 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.user_icon') { 5 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.workspace_icon') { 5 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.attachment') { 10 }
      stub(ChorusConfig.instance).[]('file_sizes_mb.hd_upload') { 4096 }
      stub(ChorusConfig.instance).[]('execution_timeout_in_minutes') { 15 }
      stub(ChorusConfig.instance).[]('default_preview_row_limit') { 20 }
      stub(ChorusConfig.instance).oracle_configured? { true }
      get :show
    end
  end

  describe "#version" do
    it "shows the build SHA if the version_build file exists" do
      stub(File).exists? { true }
      stub(File).read { "foobarbaz" }
      get :version
      response.body.should == "foobarbaz"
    end

    it "does not show the build SHA (or crash) if the version_build file does not exist" do
      stub(File).exists? { false }
      get :version
      response.body.should == Chorus::VERSION::STRING
    end
  end
end
