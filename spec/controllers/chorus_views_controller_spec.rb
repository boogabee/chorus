require 'spec_helper'

describe ChorusViewsController, :greenplum_integration do
  let(:gpdb_data_source) { GreenplumIntegration.real_data_source }
  let(:account) { gpdb_data_source.owner_account }
  let(:user) { account.owner }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.find_by_name('test_schema') }
  let(:workspace) { workspaces(:public) }
  let(:dataset) { datasets(:table) }
  let(:workfile) { workfiles(:public) }

  before do
    log_in user
  end

  describe "#create" do
    context "when creating a chorus view from a dataset" do
      let(:options) {
        HashWithIndifferentAccess.new(
            :query => "Select * from base_table1",
            :schema_id => schema.id,
            :source_object_id => dataset.id,
            :source_object_type => 'dataset',
            :object_name => "my_chorus_view",
            :workspace_id => workspace.id
        )
      }

      it "uses authorization" do
        mock(controller).authorize!(:can_edit_sub_objects, workspace)
        post :create, options
      end

      it "creates a chorus view" do
        expect {
          post :create, options
        }.to change { GpdbDataset.chorus_views.count }.by(1)

        chorus_view = GpdbDataset.chorus_views.last
        chorus_view.name.should == "my_chorus_view"
        chorus_view.workspace.should == workspace
      end

      it "presents the new Chorus View" do
        post :create, options
        response.code.should == "201"
        decoded_response[:query].should == "Select * from base_table1"
        decoded_response[:schema][:id].should == schema.id
        decoded_response[:object_name].should == "my_chorus_view"
        decoded_response[:workspace][:id].should == workspace.id
      end

      it "creates an event" do
        post :create, options

        the_event = Events::Base.last
        the_event.action.should == "ChorusViewCreated"
        the_event.source_object.id.should == dataset.id
        the_event.source_object.should be_a(Dataset)
        the_event.workspace.id.should == workspace.id
      end

      generate_fixture "workspaceDataset/chorusView.json" do
        post :create, options
      end
    end

    context "when creating a chorus view from a workfile" do
      let(:options) {
        HashWithIndifferentAccess.new(
            :query => "Select * from base_table1",
            :schema_id => schema.id,
            :source_object_id => workfile.id,
            :source_object_type => 'workfile',
            :object_name => "my_chorus_view",
            :workspace_id => workspace.id
        )
      }

      it "uses authorization" do
        mock(controller).authorize!(:can_edit_sub_objects, workspace)
        post :create, options
      end

      it "creates a chorus view" do
        post :create, options

        chorus_view = GpdbDataset.chorus_views.last
        chorus_view.name.should == "my_chorus_view"
        chorus_view.workspace.should == workspace

        response.code.should == "201"
        decoded_response[:query].should == "Select * from base_table1"
        decoded_response[:schema][:id].should == schema.id
        decoded_response[:object_name].should == "my_chorus_view"
        decoded_response[:workspace][:id].should == workspace.id
      end

      it "creates an event" do
        post :create, options

        the_event = Events::Base.last
        the_event.action.should == "ChorusViewCreated"
        the_event.source_object.id.should == workfile.id
        the_event.source_object.should be_a(Workfile)
        the_event.workspace.id.should == workspace.id
      end
    end

    context "when query is invalid" do
      let(:options) {
        HashWithIndifferentAccess.new(
            :query => "Select * from non_existing_table",
            :schema_id => schema.id,
            :object_name => "invalid_chorus_view",
            :workspace_id => workspace.id,
            :source_object_id => dataset.id,
            :source_object_type => 'dataset'
        )
      }

      it "responds with unprocessible entity" do
        post :create, options
        response.code.should == "422"
        decoded = JSON.parse(response.body)
        decoded['errors']['fields']['query']['GENERIC'].should be_present
      end
    end
  end

  describe "#duplicate" do
    let(:chorus_view) { datasets(:executable_chorus_view) }

    let(:options) { { :id => chorus_view.id, :object_name => 'duplicate_chorus_view' } }

    it "duplicate the chorus view" do
      expect { post :duplicate, options }.to change(GpdbDataset.chorus_views, :count).by(1)

      new_chorus_view = GpdbDataset.chorus_views.last
      new_chorus_view.name.should == "duplicate_chorus_view"
      chorus_view.workspace.source_datasets.should_not include(new_chorus_view)

      response.code.should == "201"
      decoded_response[:query].should == chorus_view.query
      decoded_response[:schema][:id].should == schema.id
      decoded_response[:object_name].should == "duplicate_chorus_view"
      decoded_response[:workspace][:id].should == workspace.id
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      post :duplicate, options
    end

    it "creates an event" do
      post :duplicate, options

      new_chorus_view = GpdbDataset.chorus_views.last

      the_event = Events::Base.last
      the_event.action.should == "ChorusViewCreated"
      the_event.source_object.id.should == chorus_view.id
      the_event.source_object.should be_a(ChorusView)
      the_event.workspace.id.should == workspace.id
      the_event.dataset.id.should == new_chorus_view.id
    end
  end

  describe "#update" do
    let(:chorus_view) { datasets(:executable_chorus_view) }

    let(:options) do
      {
        :id => chorus_view.to_param,
        :query => 'select 2;'
      }
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      put :update, options
    end

    it "updates the definition of chorus view" do
      put :update, options
      response.should be_success
      decoded_response[:query].should == 'select 2;'
      chorus_view.reload.query.should == 'select 2;'
    end

    it "creates an event" do
      put :update, options

      the_event = Events::Base.last
      the_event.action.should == "ChorusViewChanged"
      the_event.dataset.should == chorus_view
      the_event.actor.should == user
      the_event.workspace.should == workspace
    end

    context "as a user who is not a workspace member" do
      let(:user) { users(:not_a_member) }

      it "does not allow updating the chorus view" do
        put :update, :id => chorus_view.to_param,
            :workspace_dataset => {
              :query => 'select 2;'
            }
        response.should be_forbidden
        chorus_view.reload.query.should_not == 'select 2;'
      end
    end
  end

  describe "#destroy" do
    let(:chorus_view) { datasets(:chorus_view) }

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, :id => chorus_view.to_param
    end

    it "lets a workspace member soft delete a chorus view" do
      delete :destroy, :id => chorus_view.to_param
      response.should be_success
      chorus_view.reload.deleted?.should be_true
    end

  end

  describe "#convert" do
    let(:chorus_view) do
      datasets(:convert_chorus_view)
    end

    before do
      chorus_view.schema = schema
      chorus_view.save!
    end

    after do
      schema.connect_with(account).execute("DROP VIEW IF EXISTS \"test_schema\".\"Gretchen\"")
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, chorus_view.workspace)
      post :convert, :id => chorus_view.to_param, :object_name => "Gretchen", :workspace_id => workspace.id
    end

    context "When there is no error in creation" do
      it "creates a database view" do
        expect {
          post :convert, :id => chorus_view.to_param, :object_name => "Gretchen", :workspace_id => workspace.id
          response.should be_success
        }.to change(GpdbView, :count).by(1)
      end

      it "creates an event" do
        expect {
          post :convert, :id => chorus_view.to_param, :object_name => "Gretchen", :workspace_id => workspace.id
        }.to change(Events::Base, :count).by(1)

        the_event = Events::Base.last
        the_event.action.should == "ViewCreated"
        the_event.source_dataset.id.should == chorus_view.id
        the_event.source_dataset.should be_a(Dataset)
        the_event.workspace.id.should == chorus_view.workspace.id
      end
    end

    context "when create view statement causes an error" do
      before do
        any_instance_of(::ActiveRecord::ConnectionAdapters::JdbcAdapter) do |conn|
          stub(conn).exec_query { raise ActiveRecord::StatementInvalid }
        end
      end
      it "raises an Error" do
        expect {
          post :convert, :id => chorus_view.to_param, :object_name => "Gretchen", :workspace_id => workspace.id
        }.to_not change(GpdbView, :count)

        response.should_not be_success
      end
    end

    context "when database view already exists" do
      before do
        schema.connect_with(account).create_view("Gretchen", "SELECT 1")
      end

      it "raises an Error" do
        expect {
          post :convert, :id => chorus_view.to_param, :object_name => "Gretchen", :workspace_id => workspace.id
        }.to_not change(GpdbView, :count)

        response.should_not be_success
      end

    end
  end
end
