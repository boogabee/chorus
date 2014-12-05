require 'spec_helper'

describe BulkData do
  let(:user_columns) { %w(first_name last_name username admin email title dept notes) }
  let(:user_name) { users(:admin).username }

  after do
    File.delete file_name if defined?(file_name) && File.exists?(file_name)
  end

  describe "create_fake_users" do
    let(:file_name) { "fake_file.csv" }

    it "creates a file with header when user count =0" do
      BulkData.create_fake_users(file_name, 0)
      output_file = File.new(file_name)
      output_file.readline.should == user_columns.to_csv
      expect { output_file.readline }.to raise_error(EOFError)
    end
  end

  describe "loading users from a CSV file" do
    let(:file_name) { "input_users.csv" }

    before do
      BulkData.create_fake_users(file_name, 2)
      CSV.open(file_name, 'a') do |file|
        file << %w(Charlie Chambers chch t chch@somewhere.com ThisGuy Nowhere hahaha)
      end
    end

    it "load all the users into the database" do
      expect {
        BulkData.load_users_from_csv(file_name, user_name)
      }.to change { User.count }.by(3)
      charlie = User.last
      charlie.first_name.should == 'Charlie'
      charlie.last_name.should == 'Chambers'
      charlie.username.should == 'chch'
      charlie.should be_admin
      charlie.email.should == 'chch@somewhere.com'
      charlie.title.should == 'ThisGuy'
      charlie.dept.should == 'Nowhere'
      charlie.notes.should == 'hahaha'
    end

    it "creates the events" do
      expect {
        BulkData.load_users_from_csv(file_name, user_name)
      }.to change { Events::UserAdded.count }.by(3)
    end
  end

  describe "create workspaces" do
    it "creates random workspaces" do
      expect {
        BulkData.create_workspaces(5)
      }.to change { Workspace.count }.by(5)
    end

    it "creates the events for creating workspaces" do
      expect {
        expect {
          BulkData.create_workspaces(2)
        }.to change { Events::Base.count }.by(4)
      }.to change { Events::MembersAdded.count }.by(2)
    end
  end

  describe "add sandboxes", :greenplum_integration do
    before do
      BulkData.create_workspaces(2)
    end

    it "adds a sandbox to all workspaces" do
      expect {
        expect {
          BulkData.add_sandboxes(user_name, GreenplumIntegration.real_data_source.name)
        }.to change { Workspace.where(:sandbox_id => nil).count }.by_at_most(-2)
      }.to change { Events::WorkspaceAddSandbox.count }.by_at_least(2)
    end
  end

  describe "add workfiles" do
    before do
      BulkData.create_workspaces(2)
    end

    it "adds the workfiles to workspaces" do
      expect {
        expect {
          BulkData.add_workfiles(user_name, 2)
        }.to change { Workfile.count }.by_at_least(4)
      }.to change { Events::WorkfileCreated.count }.by_at_least(4)
    end
  end
end