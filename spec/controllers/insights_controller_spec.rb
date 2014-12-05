require 'spec_helper'

describe InsightsController do
  describe "#create" do
    before do
      log_in user
    end

    let(:user) { note.actor }
    let(:note) { Events::NoteOnDataSource.last }
    let(:note_id) { note.id }
    let(:post_params) { { :note => { :note_id => note_id } } }

    it "returns status 201" do
      post :create, post_params
      response.code.should == "201"
    end

    it "returns the note" do
      mock_present do |insight|
        insight.should == note
      end
      post :create, post_params
    end

    it "marks the NOTE as an insight" do
      post :create, post_params
      note.reload.should be_insight
      note.promoted_by.should == user
      note.promotion_time.should_not be_nil
    end

    context "when the user promoting is not the actor" do
      let(:user) { users(:not_a_member) }
      let(:note) { events(:note_on_public_workfile) }

      it "should allow them to promote the note" do
        post :create, post_params
        note.reload.should be_insight
        note.promoted_by.should == user
        note.promotion_time.should_not be_nil
      end
    end

    context 'when the note is private' do
      let(:note) { events(:note_on_no_collaborators_private_workfile) }

      context 'when the user does not have access' do
        let(:user) { users(:not_a_member) }

        it 'returns 404' do
          post :create, post_params

          response.code.should == '404'
        end
      end

      context "when the user is admin" do
        let(:user) { users(:admin) }

        it "returns status 201" do
          post :create, post_params
          response.code.should == "201"
        end
      end
    end

    context 'with an invalid id' do
      let(:note_id) { -1 }
      it 'returns 404' do
        post :create, post_params
        response.code.should == "404"
      end
    end
  end

  describe '#destroy' do
    before { log_in user }
    let(:user) { users(:the_collaborator) }
    let!(:note) { Events::NoteOnWorkspace.last.tap(&:promote_to_insight) }

    context "when the note is demotable by the current user" do
      before do
        any_instance_of(Events::NoteOnWorkspace) { |note| stub(note).demotable_by(user) { true } }
      end

      it "toggles the insight field on the given note" do
        expect {
          post :destroy, {id: note.id}
          response.code.should == "200"
        }.to change { note.reload.insight? }.from(true).to(false)
      end
    end

    context "when the note is NOT demotable by the current user" do
      before do
        any_instance_of(Events::NoteOnWorkspace) { |note| stub(note).demotable_by(user) { false } }
      end

      it "refuses to toggle the insight field on the given note" do
        expect {
          post :destroy, {id: note.id}
          response.code.should == "403"
        }.not_to change { note.reload.insight? }.from(true)
      end
    end
  end

  describe "#publish (POST to /publish)" do
    before do
      log_in user
      note.insight = true;
      note.save!
    end

    let(:user) { note.actor }
    let(:note) { Events::NoteOnWorkspace.last }
    let(:note_id) { note.id }
    let(:post_params) { { :note => { :note_id => note_id } } }

    it "returns status 201" do

      post :publish, post_params
      response.code.should == "201"
    end

    it "returns the note" do
      mock_present do |insight|
        insight.should == note
      end
      post :publish, post_params
    end

    it "marks the NOTE as published" do
      post :publish, post_params
      note.reload.should be_published
    end

    context 'when the note is private' do
      let(:note) { events(:note_on_no_collaborators_private_workfile) }

      context 'when the user does not have access' do
        let(:user) { users(:not_a_member) }

        it "returns permission denied status code" do
          post :publish, post_params

          response.code.should == '404'
        end
      end

      context "when the user is admin" do
        let(:user) { users(:admin) }

        it "returns status 201" do
          post :publish, post_params
          response.code.should == "201"
        end
      end

      context "makes the note public" do
        let(:admin_user) { users(:admin) }
        let(:non_member_user) { users(:not_a_member) }
        before do
          log_in admin_user
          post :publish, post_params
        end

        it "returns the note for user" do
          log_in non_member_user
          get :index

          response.code.should == "200"

          decoded_response.map(&:id).should include(note.id)
        end
      end

      context "checks the Note should be insight first" do
        let(:note_on_workfile) { Events::NoteOnWorkfile.last }
        let(:note_id) { note_on_workfile.id }
        let(:user) { note_on_workfile.actor }

        before do
          note_on_workfile.insight = false
          note_on_workfile.save!
        end

        it "returns an error " do
          post :publish, post_params

          response.code.should == '422'
          response.body.should include "Note has to be an insight first"
        end
      end
    end
  end

  describe "#unpublish (POST to /unpublish)" do
    before do
      log_in user
      note.insight = true
      note.published = true
      note.save!
    end

    let(:user) { note.actor }
    let(:note) { Events::NoteOnWorkspace.last }
    let(:note_id) { note.id }
    let(:post_params) { { :note => { :note_id => note_id } } }

    it "returns status 201" do
      post :unpublish, post_params
      response.code.should == "201"
    end

    it "returns the note" do
      mock_present do |insight|
        insight.should == note
      end
      post :unpublish, post_params
    end

    it "marks the NOTE as unpublished" do
      post :unpublish, post_params
      note.reload.should_not be_published
    end

    context 'when the note is private' do
      let(:note) { events(:note_on_no_collaborators_private_workfile) }

      context 'when the user does not have access' do
        let(:user) { users(:not_a_member) }

        it "returns permission denied status code" do
          post :unpublish, post_params

          response.code.should == "403"
        end
      end

      context "when the user is admin" do
        let(:user) { users(:admin) }

        it "returns status 201" do
          post :unpublish, post_params
          response.code.should == "201"
        end
      end

      context "makes the note private" do
        let(:admin_user) { users(:admin) }
        let(:non_member_user) { users(:not_a_member) }
        before do
          log_in admin_user
          post :unpublish, post_params
        end

        it "does not return the note for user" do
          log_in non_member_user
          get :index

          response.code.should == "200"

          decoded_response.map(&:id).should_not include(note.id)
        end
      end

      context "checks the Note should be published first" do
        let(:note_on_workfile) { Events::NoteOnWorkfile.last }
        let(:note_id) { note_on_workfile.id }
        let(:user) { note_on_workfile.actor }

        before do
          note_on_workfile.insight = true
          note_on_workfile.published = false
          note_on_workfile.save!
        end

        it "returns an error " do
          post :unpublish, post_params

          response.code.should == '422'
          response.body.should include "Note has to be published first"
        end
      end
    end
  end

  describe "#index (GET)" do
    before do
      log_in user
    end

    let(:user) { users(:owner) }
    let(:insight) { events(:insight_on_greenplum) }
    let(:non_insight) { events(:note_on_greenplum) }
    let(:public_workspace) { workspaces(:public) }
    let!(:workspace_insight) { Events::NoteOnWorkspace.by(user).add(
        :workspace => public_workspace,
        :body => 'Come see my awesome workspace!',
        :insight => true,
        :promotion_time => Time.current(),
        :promoted_by => user) }

    it "presents the insights" do
      mock_present do |models, ignored, options|
        models.should include(insight)
        options.should == {:activity_stream => true}
      end
      get :index, :entity_type => 'dashboard'
      response.code.should == "200"
    end

    it_behaves_like "a paginated list"

    it "should not include any non-insights" do
      mock_present do |models|
        models.should_not include(non_insight)
      end
      get :index, :entity_type => 'dashboard'
    end

    it "orders insights with the most recent first" do
      mock_present do |models|
        models.first.id.should > models.second.id
      end
      get :index, :entity_type => 'dashboard'
    end

    context "when the insight is private" do
      let(:private_insight) { events(:note_on_no_collaborators_private_workfile) }
      let(:user) { users(:not_a_member) }

      before do
        private_insight.insight = true
        private_insight.promotion_time = Time.current
        private_insight.promoted_by = private_insight.actor
        private_insight.save!
      end

      it "is not shown to a non-admin" do
        mock_present do |models|
          models.should_not include(private_insight)
        end
        get :index, :entity_type => 'dashboard'
      end

      context "when user is an admin" do
        let(:user) { users(:admin) }
        it "should show insights" do
          mock_present do |models|
            models.should include(private_insight)
          end
          get :index, :entity_type => 'dashboard'
        end
      end

    end

    context "when getting insights for the dashboard" do
      it "returns all insights " do
        mock_present { |models|
          models.should include(workspace_insight)
          models.should include(insight)
        }
        get :index, :entity_type => "dashboard"
        response.code.should == "200"
      end

      it "returns all insights as default" do
        mock_present { |models|
          models.should include(workspace_insight)
          models.should include(insight)
        }
        get :index
        response.code.should == "200"
      end
    end

    context "when getting insight for a workspace" do
      it "returns insights for the particular workspace only" do
        mock_present { |models|
          models.should include(workspace_insight)
          models.should_not include(insight)
        }
        get :index, :entity_type => "workspace", :entity_id => public_workspace.id
        response.code.should == "200"
      end
    end
  end
end
