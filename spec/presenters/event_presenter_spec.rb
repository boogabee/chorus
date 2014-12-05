require "spec_helper"

describe EventPresenter, :type => :view do
  let(:gpdb_data_source) { FactoryGirl.create(:gpdb_data_source) }
  let(:current_user) { users(:owner) }
  let(:sub_presenter_options) { {:succinct => true, :activity_stream => true} }

  before do
    set_current_user(current_user)
  end

  describe "#simple_hash" do
    subject { EventPresenter.new(event, view, options).simple_hash }
    let(:options) { {} }
    let(:event) { events(:note_on_greenplum) }

    it "has targets and additional_data values in it" do
      subject[:data_source].should be
      subject["body"].should == 'i am a comment with greenplumsearch in me'
    end
  end

  describe "#to_hash" do
    subject { EventPresenter.new(event, view, options) }
    let(:options) { {} }

    context "when rendering the activity stream" do
      let(:options) { {:activity_stream => true, :succinct => true } }

      context "SourceTableCreated" do
        let(:dataset) { datasets(:table) }
        let(:event) { FactoryGirl.create(:source_table_created_event, :dataset => dataset) }

        it "does not render datasets with their schemas or associated workspaces" do
          hash = subject.to_hash
          hash[:dataset].should == DatasetPresenter.present(dataset, view, sub_presenter_options)
          hash[:dataset][:associated_workspaces].should be_empty
        end
      end

      context "NoteOnWorkspace" do
        let(:workspace_with_sandbox) { workspaces(:public) }
        let(:event) { FactoryGirl.create(:note_on_workspace_event, :workspace => workspace_with_sandbox) }

        it "presents the succinct hash of the workspace" do
          hash = subject.to_hash
          hash[:workspace].should == WorkspacePresenter.new(workspace_with_sandbox, view, sub_presenter_options).to_hash
        end
      end
    end

    context "when rendering notifications" do
      let(:options) { {:read_receipts => true} }

      context "NoteOnWorkspace" do
        let(:workspace_with_sandbox) { workspaces(:public) }
        let(:event) { current_user.notifications.first.event }

        it "renders the event with a :read key based on the current user" do
          hash = subject.to_hash
          hash[:read].should be_false
        end
      end
    end

    context "Non-note event" do
      let(:event) { FactoryGirl.create(:data_source_created_event, :data_source => gpdb_data_source) }

      it "includes the 'id', 'timestamp', 'actor', 'action'" do
        hash = subject.to_hash
        hash[:id].should == event.id
        hash[:timestamp].should == event.created_at
        hash[:action].should == "DataSourceCreated"
        hash[:actor].should == Presenter.present(event.actor, view, sub_presenter_options)
      end

      it "presents all of the event's 'targets', using the same names" do
        special_data_source = FactoryGirl.build(:gpdb_data_source)
        special_user = FactoryGirl.build(:user)

        stub(event).targets do
          {
              :special_data_source => special_data_source,
              :special_user => special_user
          }
        end

        hash = subject.to_hash
        hash[:special_data_source].should == Presenter.present(special_data_source, view, sub_presenter_options)
        hash[:special_user].should == Presenter.present(special_user, view, sub_presenter_options)
      end

      it "includes all of the event's 'additional data'" do
        stub(event).additional_data do
          {
              :some_key => "foo",
              :some_other_key => "bar"
          }
        end

        hash = subject.to_hash
        hash[:some_key].should == "foo"
        hash[:some_other_key].should == "bar"
      end
    end

    context "Note event" do
      let(:event) { FactoryGirl.create(:note_on_data_source_event) }

      it "returns the correct hash for a note" do
        hash = subject.to_hash
        hash[:action].should == "NOTE"
        hash[:action_type].should == "NoteOnDataSource"
      end

      it "sanitizes notes' body" do
        stub(event).additional_data do
          {
              :body => "<script>foo</script>"
          }
        end

        hash = subject.to_hash
        hash[:body].should_not include('<')
        hash[:body].should_not include('>')
      end

      it "allows links" do
        stub(event).additional_data do
          {
              :body => "<a href='http://google.com'>foo</a>"
          }
        end

        hash = subject.to_hash
        hash[:body].should include('<')
        hash[:body].should include('>')
      end

      context "with an attachment" do
        let(:event) { FactoryGirl.create(:note_on_workfile) }
        let(:attachment) { Attachment.first }
        let(:dataset) { datasets(:table) }
        let(:workfile) { workfiles(:public) }
        let(:note_work_flow_result) { NotesWorkFlowResult.new({:result_id => "0.1234321"}) }

        it "contains the attachment" do
          event.workspace.sandbox = dataset.schema
          event.workspace.save
          stub(event).attachments { [attachment] }
          stub(event).datasets { [dataset] }
          stub(event).workfiles { [workfile] }
          stub(event).notes_work_flow_results { [note_work_flow_result] }
          hash = subject.to_hash
          hash[:attachments].should be_present
          hash[:attachments][0][:entity_type].should == 'attachment'
          hash[:attachments][1][:entity_type].should == 'dataset'
          hash[:attachments][2][:entity_type].should == 'workfile'
          hash[:attachments][1][:workspace].should == event.workspace
          hash[:attachments][1][:entity_subtype].should == "SANDBOX_TABLE"
          hash[:attachments][3][:entity_type].should == "work_flow_result"
          hash[:attachments][3][:id].should == note_work_flow_result.result_id
          hash[:attachments][3][:workfile_id].should == event.workfile.id
        end
      end

      context "with a workfile image attachment" do
        let(:event) { FactoryGirl.create(:note_on_workspace_event) }
        let(:workfile) { Workfile.find_by_file_name("image.png") }

        it "contains the images icon url" do
          event.workspace.save
          stub(event).workfiles { [workfile] }
          hash = subject.to_hash
          hash[:attachments].should be_present
          hash[:attachments][0][:entity_type].should == 'workfile'
          hash[:attachments][0][:version_info][:icon_url].should =~ /\/workfile_versions\/.*image\?style=icon/
        end
      end
    end

    context "Workfile Result event" do
      let(:event) { FactoryGirl.create(:workfile_result) }
      let(:note_work_flow_result) { NotesWorkFlowResult.new({:result_id => "0.1234321"}) }

      it "contains the attachment" do
        stub(event).notes_work_flow_results { [note_work_flow_result] }

        hash = subject.to_hash
        hash[:attachments][0][:entity_type].should == "work_flow_result"
        hash[:attachments][0][:id].should == note_work_flow_result.result_id
      end
    end

    context "Event with comments" do
      let(:event) { events(:note_on_greenplum) }

      it "has a comments array on it" do
        hash = subject.to_hash
        hash[:comments].should_not be_nil
      end

      it "has correct formatting of comments" do
        hash = subject.to_hash
        hash[:comments].count.should > 1
        hash[:comments].each do | comment |
          comment[:body].should_not be_nil
          comment[:author].should_not be_nil
        end
      end
    end

    context "events that are insight" do
      let(:event) { events(:note_on_greenplum) }
      let(:user) { users(:owner) }

      before do
        event.insight = true
        event.promoted_by = user
        event.promotion_time = Time.current()
      end

      it "has hash for insights" do
        hash = subject.to_hash
        hash[:is_insight].should be_true
        hash[:promoted_by].should == Presenter.present(user, view, sub_presenter_options)
        hash[:promotion_time].should == event.promotion_time
        hash[:is_published].should == false
      end

      context "insights that are published" do
        before do
          event.published = true
        end

        it "should be published" do
          hash = subject.to_hash
          hash[:is_published].should == true
        end
      end
    end

    context "events with errors" do
      let(:event) { events(:import_failed_with_model_errors) }
      let(:user) { users(:owner) }

      it "presents the errors" do
        hash = subject.to_hash
        hash[:error_objects].should == ErrorPresenter.new(event.error_objects).as_json
      end
    end

    context "presenting as a comment" do
      let(:options) { {:as_comment => true} }
      let(:hash) { subject.to_hash }

      context "for a note" do
        let(:event) { events(:note_on_greenplum) }

        it "should present a restricted set" do
          hash[:body].should == event.body
          hash[:author].should == UserPresenter.new(event.actor, view, sub_presenter_options).presentation_hash
          hash[:timestamp].should == event.created_at
          hash.keys.size.should == 3
        end
      end

      context "for a workfile version" do
        let(:event) { Events::WorkfileUpgradedVersion.first }

        it "should present a restricted set" do
          hash[:body].should == event.commit_message
          hash[:author].should == UserPresenter.new(event.actor, view, sub_presenter_options).presentation_hash
          hash[:timestamp].should == event.created_at
          hash.keys.size.should == 3
        end
      end
    end
  end
end
