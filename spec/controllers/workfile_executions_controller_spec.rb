require 'spec_helper'

describe WorkfileExecutionsController do
  let(:workspace) { workspaces(:public) }
  let(:sandbox) { workspace.sandbox }
  let(:workspace_member) { users(:the_collaborator) }
  let(:workfile) {
    FactoryGirl.create :chorus_workfile, :execution_schema => sandbox, :workspace => workspace
  }
  let(:archived_workspace) { workspaces(:archived) }
  let(:archived_workfile) { workfiles(:archived) }
  let(:sql) { "Select something from somewhere" }
  let(:check_id) { '12345' }
  let(:default_row_limit) { 500 }

  describe "#create" do
    let(:user) { workspace_member }
    let(:connection) {
      object = Object.new
      stub(sandbox).connect_as(user) { object }
      object
    }

    it_behaves_like "an action that requires authentication", :post, :create, :workfile_id => '-1'

    context "as a member of the workspace" do
      before do
        log_in workspace_member
        stub.proxy(ChorusConfig.instance).[](anything)
        stub(ChorusConfig.instance).[]('default_preview_row_limit') { default_row_limit }
        stub(Workfile).find(workfile.to_param) { workfile }
        stub(workfile).execution_schema { sandbox }

      end

      it "executes the sql with the check_id and default row limit" do
        mock(CancelableQuery).new(connection, check_id, user) do
          mock(Object.new).execute(sql, hash_including(:limit => default_row_limit)) { GreenplumSqlResult.new }
        end

        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id
      end

      it "always uses default row limit, even if num_of_rows is specified" do
        mock(CancelableQuery).new(anything, anything, user) do
          mock(Object.new).execute(anything, hash_including(:limit => default_row_limit)) { GreenplumSqlResult.new }
        end

        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id, :num_of_rows => 123
      end

      it "uses the presenter for SqlResult" do
        mock(CancelableQuery).new(anything, anything, user) do
          mock(Object.new).execute(anything, hash_including(:limit => default_row_limit)) { GreenplumSqlResult.new }
        end

        mock_present { |model| model.should be_a SqlResult }
        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id
      end

      it "executes the sql with include_public_schema_in_search_path option" do
        mock(CancelableQuery).new(anything, anything, user) do
          mock(Object.new).execute(anything, hash_including(:include_public_schema_in_search_path => true)) do
            GreenplumSqlResult.new
          end
        end

        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id
      end
    end

    context "when the query has multiple result sets", :greenplum_integration do
      let(:workspace) { workspaces(:real) }
      let(:workfile) { FactoryGirl.create(:chorus_workfile, :workspace => workspace, :execution_schema => workspace.sandbox ) }
      let(:sql) do
        <<-SQL
          select 1;
          select 2;
        SQL
      end

      before { log_in users(:owner) }

      it "returns the results of the last query" do
        post :create, :workfile_id => workfile.id,
             :sql => sql, :check_id => 'doesnt_even_matter',
             :download => true, :file_name => "some"

        response.should be_success
        response.body.should match(/\?column\?\n2/)
      end
    end

    it "uses authorization" do
      log_in workspace_member
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id
    end

    it "returns an error if no check_id is given" do
      log_in workspace_member
      post :create, :workfile_id => workfile.id, :sql => sql
      response.code.should == '422'
      decoded = JSON.parse(response.body)
      decoded['errors']['fields']['check_id'].should have_key('BLANK')
    end

    context "with an archived workspace" do
      it "responds with invalid record response" do
        log_in workspace_member
        post :create, :workfile_id => archived_workfile.id, :sql => sql, :check_id => check_id
        response.code.should == "422"

        decoded = JSON.parse(response.body)
        decoded['errors']['fields']['workspace'].should have_key('ARCHIVED')
      end
    end

    context "when downloading the results" do
      let(:sql_result) {
        GreenplumSqlResult.new.tap{ |result|
          result.add_column("a", "string")
          result.add_column("b", "string")
          result.add_column("c", "string")
          result.add_row([1,2,3])
          result.add_row([4,5,6])
          result.add_row([7,8,9])
        }
      }
      let(:user) { users(:owner) }
      let(:limit) { nil }
      let(:options) { {:row_limit => limit.to_i} }

      before do
        log_in user

        stub(Workfile).find(workfile.to_param) { workfile }
        stub(workfile).execution_schema { sandbox }

        mock(CancelableQuery).new(connection, check_id, user) do
          mock(Object.new).stream(sql, options) { 'response' }
        end
      end

      it "sets content disposition: attachment" do
        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id, :download => true, :file_name => "some"
        response.headers['Content-Disposition'].should include("attachment")
        response.headers['Content-Disposition'].should include('filename="some.csv"')
        response.headers['Content-Type'].should == 'text/csv'
      end

      it "returns the streamer response" do
        post :create, :workfile_id => workfile.id, :schema_id => workspace.sandbox.id, :sql => sql, :check_id => check_id, :download => true, :file_name => "some"
        response.body.should == 'response'
      end

      it "does not limit the results when num_of_rows is not set" do
        post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id, :download => true, :file_name => "some"
      end

      context "when limit is passed" do
        let(:limit) { "123" }

        it "limits the results when to num_of_rows" do
          post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id, :download => true, :file_name => "some", :num_of_rows => limit
        end
      end

      it_behaves_like "prefixed file downloads" do
        let(:do_request) { post :create, :workfile_id => workfile.id, :sql => sql, :check_id => check_id, :download => true, :file_name => "some" }
        let(:expected_filename) { "some.csv" }
      end
    end

    describe "rspec fixtures", :greenplum_integration do
      let(:schema) { GpdbSchema.find_by_name!('test_schema') }

      before do
        log_in users(:admin)
        workfile.execution_schema = schema
        workfile.save!
      end

      generate_fixture "workfileExecutionResults.json" do
        post :create, :workfile_id => workfile.id, :sql => 'select * from base_table1', :check_id => check_id
      end

      generate_fixture "workfileExecutionResultsWithWarning.json" do
        post :create, :workfile_id => workfile.id, :sql => 'create table table_with_warnings (id INT PRIMARY KEY); select * from base_table1', :check_id => check_id
      end

      generate_fixture "workfileExecutionResultsEmpty.json" do
        post :create, :workfile_id => workfile.id, :sql => '', :check_id => check_id
      end

      generate_fixture "workfileExecutionError.json" do
        post :create, :workfile_id => workfile.id, :sql => 'select hippopotamus', :check_id => check_id
        response.code.should == "422"
      end

      after do
        admin = users(:admin)
        schema.connect_as(admin).drop_table("table_with_warnings")
      end
    end
  end

  describe "#destroy" do
    before do
      log_in workspace_member
    end

    it "cancels the query for the given id" do
      mock(CancelableQuery).cancel(check_id, workspace_member)
      delete :destroy, :workfile_id => workfile.id, :id => check_id
      response.should be_success
    end

    it "returns an error if no check_id is given" do
      delete :destroy, :workfile_id => workfile.id, :id => ''
      response.code.should == '422'
      decoded = JSON.parse(response.body)
      decoded['errors']['fields']['check_id'].should have_key('BLANK')
    end

    context "with an archived workspace" do
      it "responds with invalid record response" do
        delete :destroy, :workfile_id => archived_workfile.id, :id => check_id
        response.code.should == "422"

        decoded = JSON.parse(response.body)
        decoded['errors']['fields']['workspace'].should have_key('ARCHIVED')
      end
    end
  end
end
