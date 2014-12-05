require "spec_helper"

describe NotesController do
  let(:user) { users(:owner) }

  describe "#create" do
    before do
      log_in user
    end

    let(:model) { workspaces(:public) }
    let(:entity_type) { model.class.name }
    let(:entity_id) { model.id.to_s }
    let(:attributes) { { :entity_type => entity_type, :entity_id => entity_id, :body => "I'm a note" } }

    it "creates a note on the model specified by the 'entity_type' and 'entity_id'" do
      mock.proxy(Events::Note).build_for(model, attributes.stringify_keys)
      expect {
        post :create, attributes
      }.to change(Events::Note, :count).by(1)
      response.code.should == "201"
    end

    it "sanitizes the body of note" do
      mock.proxy(Events::Note).build_for(model, attributes.merge(:body => "<b>not evil</b>").stringify_keys)
      post :create, attributes.merge!(:body => "<b>not evil</b><script>alert('Evil!')</script>")
      response.code.should == "201"
    end

    it "uses authorization" do
      mock(controller).authorize!(:create_note_on, model)
      post :create, attributes
    end

    it "raises an exception if there is no model with the given entity id" do
      post :create, attributes.merge(:entity_id => "bogus")
      response.code.should == "404"
    end

    context "when adding a note to a workspace" do
      let(:workspace) { workspaces(:public) }
      let(:entity_type) { "workspace" }
      let(:entity_id) { workspace.id }

      it "associates the datasets to the Note" do
        post :create, attributes.merge(:dataset_ids => associated_datasets.to_param)
        response.code.should == "201"
        Events::NoteOnWorkspace.last.datasets.should == associated_datasets
      end

      it "associates the workfiles to the Note" do
        associated_workfiles = workspace.workfiles[0..1]
        associated_workfile_ids = associated_workfiles.map(&:id)
        post :create, attributes.merge(:workfile_ids => associated_workfile_ids)
        response.code.should == "201"
        Events::NoteOnWorkspace.last.workfiles.map(&:id).should =~ associated_workfiles.map(&:id)
      end

      context "when creator is not a workspace member" do
        let(:user) { users(:no_collaborators) }
        let(:workspace) { workspaces(:private) }

        it "returns a forbidden status" do
          post :create, attributes
          response.code.should == "403"
        end
      end

      context "when the workspace is archived" do
        let(:workspace) { workspaces(:archived) }

        it "responds with an error code" do
          post :create, attributes
          response.code.should == "422"
        end
      end

      context "when given users to notify" do
        let(:users_to_notify) { [users(:owner), users(:no_collaborators)] }

        it "generates notifications for the users" do
          post :create, attributes.merge(:recipients => users_to_notify.map(&:id), :body => "Notify people note")
          response.code.should == "201"
          users_to_notify.each do |user|
            user.notifications.last.event.body.should == "Notify people note"
          end
        end
      end
    end

    context "when adding a note with a work flow result attachment" do
      let(:model) { workfiles(:alpine_flow) }
      let(:attributes) do
        {
            :entity_type => entity_type,
            :entity_id => entity_id,
            :body => "I'm a note",
            :result_id => "123"
        }
      end

      it "should create a notes_work_flow_result record" do
        expect do
          post :create, attributes
        end.to change(NotesWorkFlowResult, :count).by(1)

        NotesWorkFlowResult.last.result_id.should == "123"
        response.should be_success
      end
    end
  end

  describe "#update" do
    before do
      log_in user
    end

    let(:note) { events(:note_on_greenplum) }
    let(:attributes) { { :id => note.id, :body => "Some crazy content" } }

    context "as the note owner" do
      let(:user) { note.actor }

      it "update the note on a gpdb data source" do
        post :update, attributes
        response.code.should == "200"

        note.reload.body.should == "Some crazy content"
      end

      it "sanitize the Note body before update" do
        post :update, attributes.merge(:body => "Hi there<script>alert('haha I am evil')</script>")
        response.code.should == "200"

        note.reload.body.should == "Hi there"
      end
    end

    context "not as the note owner" do
      let(:user) { users(:the_collaborator) }

      it "update the note on a gpdb data source" do
        post :update, attributes
        response.code.should == "403"

        note.reload.body.should_not == "Some crazy content"
      end
    end
  end

  describe "#destroy" do
    let(:note) {
      Events::NoteOnDataSource.by(user).add(:gpdb_data_source => data_sources(:default), :body => 'i am a comment with greenplumsearch in me', :created_at => '2010-01-01 02:00')
    }

    before do
      log_in note.actor
    end

    after do
      note.destroy
    end

    it "destroys the note with the given id" do
      delete :destroy, :id => note.id
      note.reload.should be_deleted
      Events::NoteOnDataSource.find_by_id(note.id).should be_nil
    end

    it "returns an empty JSON body" do
      delete :destroy, :id => note.id
      response.body.should == "{}"
    end

    it "uses the note access to check permissions" do
      mock(controller).authorize!(:destroy, note)
      delete :destroy, :id => note.id
    end
  end
end
