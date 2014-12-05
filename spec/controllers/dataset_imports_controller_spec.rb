require 'spec_helper'

describe DatasetImportsController do
  describe "#index" do
    let(:user) { users(:owner) }
    let(:source_dataset) { import_three.source_dataset }

    let(:import_one) { imports(:one) }
    let(:import_two) { imports(:now) }
    let(:import_three) { imports(:three) }

    before do
      log_in user
    end

    it_behaves_like "a paginated list" do
      let(:params) { {:workspace_id => import_three.workspace_id, :dataset_id => source_dataset.to_param} }
    end

    it "shows the latest imports for a dataset as the source dataset" do
      get :index, :workspace_id => import_three.workspace_id, :dataset_id => source_dataset.to_param
      response.should be_success
      decoded_response.should_not be_nil
      decoded_response.length.should == 3
    end

    context "for a destination dataset" do
      let(:workspace) { import_three.workspace }
      let(:destination_dataset) { workspace.sandbox.datasets.create!({:name => 'new_table_for_import'}, :without_protection => true) }

      it "shows the latest imports for a destination dataset" do
        get :index, :workspace_id => workspace.to_param, :dataset_id => destination_dataset.to_param
        response.should be_success
        decoded_response.length.should == 3
      end

      it 'eager loads the destination dataset' do
        mock_present do |imports|
          imports.each { |i| i.association(:destination_dataset).should be_loaded }
        end
        get :index, :workspace_id => workspace.to_param, :dataset_id => destination_dataset.to_param
      end
    end

    context "for a chorus view" do
      let(:workspace) { import_three.workspace }
      let(:destination_dataset) { FactoryGirl.create :chorus_view, :name => 'new_table_for_import', :workspace => workspace }

      it "doesn't find imports where the chorus view has the same name as a destination table" do
        get :index, :workspace_id => workspace.to_param, :dataset_id => destination_dataset.to_param
        response.should be_success
        decoded_response.length.should == 0
      end

      it "does return imports where the chorus view is the source" do
        source_dataset.type = "ChorusView"
        source_dataset.save!
        get :index, :workspace_id => import_three.workspace_id, :dataset_id => source_dataset.to_param
        decoded_response.length.should == 3
      end
    end

    it "authorizes" do
      log_in users(:default)
      get :index, :workspace_id => workspaces(:private).to_param, :dataset_id => source_dataset.to_param

      response.should be_forbidden
    end

    generate_fixture 'workspaceImportSet.json' do
      get :index, :workspace_id => import_three.workspace_id, :dataset_id => source_dataset.id
      response.should be_success
    end

    generate_fixture 'csvImportSet.json' do
      get :index, :workspace_id => imports(:csv).workspace_id, :dataset_id => datasets(:csv_import_table).id
      response.should be_success
    end
  end

  describe "#update" do
    let(:user) { users(:admin) }
    let(:import) { imports(:one) }
    let(:success) { false }
    let(:message) { 'it failed' }

    let(:params) { {
        :id => import.id,
        :success => success.to_s,
        :format => :json,
        :message => message
    } }

    before do
      log_in user
    end

    context "for an import that has not finished" do
      before do
        import.finished_at = nil
        import.save!
      end

      it "cancels a running import" do
        any_instance_of(Import) do |import|
          mock(import).mark_as_canceled!(message)
        end

        put :update, params

        response.should be_success
      end

      it "redirects html requests back to the import console" do
        old_config = ChorusConfig.instance.config
        ChorusConfig.instance.config = ChorusConfig.instance.config.dup
        ChorusConfig.instance.config['ssl_server_port'] = 1234
        ChorusConfig.instance.config['ssl']['enabled'] = true

        put :update, params.merge(:format => :html)
        response.should redirect_to ":1234/import_console/imports"

        ChorusConfig.instance.config = old_config
      end
    end

    it "authorizes only the admin" do
      log_out
      log_in(users(:owner))
      any_instance_of(Import) do |import|
        dont_allow(import).mark_as_canceled!
      end

      put :update, params

      response.should be_forbidden
    end

    context 'when it is a csv import' do
      let(:import) { imports(:csv) }

      it 'the admin is authorized' do
        put :update, params
        response.should be_ok
      end
    end

    context "for an import that has already finished" do
      let(:finished_at) { 1.day.ago }
      before do
        import.finished_at = finished_at
        import.success = true
        import.save!
      end

      it "does nothing" do
        any_instance_of(Import) do |import|
          dont_allow(import).mark_as_canceled!.with_any_args
        end
        put :update, params
        response.should be_success
      end
    end
  end
end
