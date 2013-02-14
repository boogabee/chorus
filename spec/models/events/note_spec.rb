# encoding: utf-8
require "spec_helper"
require_relative "helpers"

describe Events::Note do
  extend EventHelpers

  let(:actor) { users(:not_a_member) }
  let(:gpdb_data_source) { data_sources(:default) }
  let(:hadoop_instance) { hadoop_instances(:hadoop) }
  let(:gnip_instance) { gnip_instances(:default) }
  let(:workspace) { workspaces(:public) }
  let(:workfile) { workfiles(:public) }
  let(:tableau_workfile) { workfiles(:tableau) }
  let(:dataset) { datasets(:table) }
  let(:hdfs_entry) do
    hadoop_instance.hdfs_entries.create!(:path => '/data/test.csv',
                                         :modified_at => "2010-10-24 22:00:00")
  end

  describe "associations" do
    it { should belong_to(:promoted_by).class_name('User') }
  end

  it "requires an actor" do
    note = Events::Note.new
    note.should_not be_valid
    note.should have_error_on(:actor_id)
  end

  describe ".insights" do
    let(:insight) { events(:insight_on_greenplum) }
    let(:normal) { events(:note_on_dataset) }

    it "should only include insights" do
      insights = described_class.insights
      insights.should include(insight)
      insights.should_not include(normal)
    end
  end

  describe "NoteOnGreenplumInstance" do
    subject do
      Events::NoteOnGreenplumInstance.create!({
          :actor => actor,
          :gpdb_data_source => gpdb_data_source,
          :body => "This is the body"
      }, :as => :create)
    end

    its(:gpdb_data_source) { should == gpdb_data_source }
    its(:targets) { should == {:gpdb_data_source => gpdb_data_source} }
    its(:additional_data) { should == {'body' => "This is the body"} }

    it_creates_activities_for { [actor, gpdb_data_source] }
    it_creates_a_global_activity
  end

  describe "NoteOnHadoopInstance" do
    subject do
      Events::NoteOnHadoopInstance.create!({
          :actor => actor,
          :hadoop_instance => hadoop_instance,
          :body => "This is the body"
      }, :as => :create)
    end

    it "sets the instance set correctly" do
      subject.hadoop_instance.should == hadoop_instance
    end

    it "sets the instance as the target" do
      subject.targets.should == {:hadoop_instance => hadoop_instance}
    end

    it "sets the body" do
      subject.body.should == "This is the body"
    end

    it_creates_activities_for { [actor, hadoop_instance] }
    it_creates_a_global_activity
  end

  describe "NoteOnHdfsFile" do
    subject do
      Events::NoteOnHdfsFile.create!({
          :actor => actor,
          :hdfs_file => hdfs_entry,
          :body => "This is the text of the note"
      }, :as => :create)
    end

    its(:hdfs_file) { should == hdfs_entry }
    its(:targets) { should == {:hdfs_file => hdfs_entry} }
    its(:additional_data) { should == {'body' => "This is the text of the note"} }

    it_creates_activities_for { [actor, hdfs_entry] }
    it_creates_a_global_activity
  end

  describe "NoteOnWorkspace" do
    subject do
      Events::NoteOnWorkspace.new({
          :actor => actor,
          :workspace => workspace,
          :body => "This is the text of the note on the workspace"
      }, :as => :create)
    end

    its(:workspace) { should == workspace }
    its(:targets) { should == {:workspace => workspace} }
    its(:additional_data) { should == {'body' => "This is the text of the note on the workspace"} }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
    it_behaves_like 'event associated with a workspace'

    it "can not be created on an archived workspace" do
      note = Events::NoteOnWorkspace.new(:workspace => workspaces(:archived), :actor => actor, :body => 'WOO!')
      note.should_not be_valid
      note.should have_error_on(:workspace)
    end

    it "is valid if the workspace later becomes archived" do
      subject.save!
      workspace.archived = 'true'
      workspace.archiver = actor
      workspace.save!
      subject.reload
      subject.should be_valid
    end
  end

  describe "NoteOnWorkfile" do
    let(:workspace) { nil }
    subject do
      Events::NoteOnWorkfile.create!({
          :actor => actor,
          :workfile => workfile,
          :workspace => workspace,
          :body => "This is the text’s of the note on the workfile"
      }, :as => :create)
    end

    its(:workfile) { should == workfile }
    its(:targets) { should == {:workfile => workfile} }
    its(:additional_data) { should == {'body' => "This is the text’s of the note on the workfile"} }

    it_creates_activities_for { [actor, workfile, workfile.workspace] }
    it_does_not_create_a_global_activity

    it "has an event on the workspace" do
      subject
      workfile.workspace.events.should include(subject)
    end

    it "can access associated workfiles when they are deleted" do
      subject
      workfile.destroy
      subject.reload.workfile.should == workfile
      subject.workfile.should be_deleted
    end

    describe "when a different workspace is passed" do
      let(:workspace) { workspaces(:private) }

      it "sets the workspace to the workspace of the workfile" do
        subject.workspace.should == workfile.workspace
      end
    end
  end

  describe "NoteOnDataset" do
    subject do
      Events::NoteOnDataset.create!({
          :actor => actor,
          :dataset => dataset,
          :body => "<3 <3 <3"
      }, :as => :create)
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:dataset => dataset} }
    its(:additional_data) { should == {'body' => "<3 <3 <3"} }

    it_creates_activities_for { [actor, dataset] }
    it_creates_a_global_activity
  end

  describe "NoteOnWorkspaceDataset" do
    subject do
      Events::NoteOnWorkspaceDataset.create({
          :actor => actor,
          :dataset => dataset,
          :workspace => workspace,
          :body => "<3 <3 <3"
      }, :as => :create)
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:dataset => dataset, :workspace => workspace} }
    its(:additional_data) { should == {'body' => "<3 <3 <3"} }

    context "when workspace is private" do
      let(:workspace) { workspaces(:private_with_no_collaborators) }

      it "is not valid if the actor is not a member of a private workspace" do
        subject.should_not be_valid
        subject.should have_error_on(:workspace).with_message(:not_a_member)
      end
    end

    it "is valid if the workspace is public" do
      workspace.should be_public
      subject.should be_valid
    end

    it_creates_activities_for { [actor, dataset, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "NoteOnGnipInstance" do
    subject do
      Events::NoteOnGnipInstance.create!({
          :actor => actor,
          :gnip_instance => gnip_instance,
          :body => "This is the body"
      }, :as => :create)
    end

    its(:gnip_instance) { should == gnip_instance }
    its(:targets) { should == {:gnip_instance => gnip_instance} }
    its(:additional_data) { should == {'body' => "This is the body"} }

    it_creates_activities_for { [actor, gnip_instance] }
    it_creates_a_global_activity
  end

  describe "search" do
    it "indexes text fields" do
      Events::Note.should have_searchable_field :body
    end

    describe "with a target" do
      let(:workfile) { workfiles(:public) }
      let(:workspace) { workfile.workspace }

      let(:subclass1) do
        Class.new(Events::Note) { has_targets :workspace, :workfile }
      end
      let(:note) { subclass1.new({:workspace => workspace, :workfile => workfile}, :as => :create) }

      it "delegates grouping, type, and security fields to its first 'target'" do
        note.grouping_id.should == workspace.grouping_id
        note.grouping_id.should_not be_blank
        note.type_name.should == workspace.type_name
        note.type_name.should_not be_blank
        note.security_type_name.should == workspace.security_type_name
      end
    end
  end

  describe "#promote_to_insight" do
    let(:actor) { users(:owner) }
    let(:event) {
      Events::NoteOnGreenplumInstance.create!({
          :actor => actor,
          :gpdb_data_source => gpdb_data_source,
          :body => "This is the body"
      }, :as => :create)
    }
    subject { event.promote_to_insight }
    before do
      set_current_user(actor)
    end

    it { should be_true }

    it "saves the note" do
      expect {
        event.promote_to_insight
      }.to change(event, :updated_at)
    end

    describe "it saves a note after promoting it to an insight" do
      subject do
        event.promote_to_insight
        event.reload
      end

      it { should be_insight }
      its(:promoted_by) { should == actor }
      its(:promotion_time) { should be_within(1.minute).of(Time.current) }
    end
  end

  describe "#build_for(model, params)" do
    let(:user) { users(:owner) }
    before do
      set_current_user(user)
    end

    context "workspace is archived" do
      it "builds a note with errors" do
        workfile.workspace.archived_at = Time.current
        workfile.workspace.archiver = user
        workfile.workspace.save!
        note = Events::Note.build_for(workfile, {
            :body => "More crazy content",
            :workspace_id => workspace.id,
            :entity_type => "workfile"
        })
        note.should_not be_valid
        note.should have_error_on(:workspace).with_message(:archived)
      end
    end

    it "builds a note on a greenplum instance" do
      gpdb_data_source = data_sources(:default)
      note = Events::Note.build_for(gpdb_data_source, {
          :body => "Some crazy content",
          :entity_type => "data_source"
      })

      note.save!
      note.should be_a(Events::NoteOnGreenplumInstance)
      note.gpdb_data_source.should == gpdb_data_source
      note.body.should == "Some crazy content"
      note.actor.should == user
    end

    it "builds a note on a hadoop instance" do
      hadoop_instance = hadoop_instances(:hadoop)
      note = Events::Note.build_for(hadoop_instance, {
          :body => "Some crazy content",
          :entity_type => "hadoop_instance"
      })

      note.save!
      note.hadoop_instance.should == hadoop_instance
      note.should be_a(Events::NoteOnHadoopInstance)
      note.body.should == "Some crazy content"
      note.actor.should == user
    end

    it "builds a note on an hdfs file" do
      note = Events::Note.build_for(hdfs_entry, {
          :body => "Some crazy content",
          :entity_type => "hdfs_file"
      })

      note.save!
      note.should be_a(Events::NoteOnHdfsFile)
      note.actor.should == user
      note.hdfs_file.hadoop_instance.should == hadoop_instance
      note.hdfs_file.path.should == "/data/test.csv"
      note.body.should == "Some crazy content"
    end

    it "builds a note on a Gnip Instance" do
      note = Events::Note.build_for(gnip_instance, {
          :body => "Some crazy content",
          :entity_type => "gnip_instance"
      })

      note.save!
      note.gnip_instance.should == gnip_instance
      note.should be_a(Events::NoteOnGnipInstance)
      note.body.should == "Some crazy content"
      note.actor.should == user
    end

    it "builds a note on a workfile" do
      note = Events::Note.build_for(workfile, {
          :body => "Workfile content",
          :entity_type => "workfile"
      })

      note.save!
      note.should be_a(Events::NoteOnWorkfile)
      note.actor.should == user
      note.workfile.should == workfile
      note.workspace.should == workfile.workspace
      note.body.should == "Workfile content"
    end

    it "builds a note on a tableau workfile" do
      note = Events::Note.build_for(tableau_workfile, {
          :body => "Workfile content",
          :entity_type => "workfile"
      })

      note.save!
      note.should be_a(Events::NoteOnWorkfile)
      note.actor.should == user
      note.workfile.should == tableau_workfile
      note.workspace.should == tableau_workfile.workspace
      note.body.should == "Workfile content"
    end

    it "builds a note on a dataset" do
      note = Events::Note.build_for(dataset, {
          :body => "Crazy dataset content",
          :entity_type => "dataset"
      })

      note.save!
      note.should be_a(Events::NoteOnDataset)
      note.actor.should == user
      note.dataset.should == dataset
      note.body.should == "Crazy dataset content"
    end

    it "builds a note on a dataset in a workspace" do
      note = Events::Note.build_for(dataset, {
          :body => "Crazy workspace dataset content",
          :workspace_id => workspace.id,
          :entity_type => "dataset"
      })

      note.save!
      note.should be_a(Events::NoteOnWorkspaceDataset)
      note.actor.should == user
      note.dataset == dataset
      note.workspace == workspace
      note.body.should == "Crazy workspace dataset content"
    end

    it "doesn't always create insights" do
      note = Events::Note.build_for(dataset, {
          :body => "Crazy workspace dataset content",
          :workspace_id => workspace.id,
          :entity_type => "dataset"
      })

      note.save!
      note.insight.should_not == true
      note.promoted_by.should == nil
      note.promotion_time.should == nil
    end

    it "builds an insight" do
      note = Events::Note.build_for(dataset, {
          :body => "Crazy workspace dataset content",
          :workspace_id => workspace.id,
          :is_insight => true,
          :entity_type => "dataset"
      })

      note.save!
      note.insight.should == true
      note.promoted_by.should == user
      note.promotion_time.should_not == nil
    end

    it "uses the target workspace over the workspace_id" do
      note = Events::Note.build_for(workfile, {
          :body => "Workfile content",
          :workspace_id => workspaces(:empty_workspace).id,
          :entity_type => "workfile"
      })

      note.save!
      note.workfile.should == workfile
      note.workspace.should == workfile.workspace


      note = Events::Note.build_for(workfile, {
          :body => "Workfile content",
          :workspace_id => workspaces(:empty_workspace).id,
          :entity_type => "workfile"
      })

      note.save!
      note.workfile.should == workfile
      note.workspace.should == workfile.workspace
    end
  end
end
