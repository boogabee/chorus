require 'spec_helper'
require 'timecop'

describe ApplicationController do

  it "has a uuid for every web request" do
    Chorus::Application.config.log_tags.first.should == :uuid
  end

  describe "rescuing from errors" do
    controller do
      def index
        head :ok
      end
    end

    before do
      log_in users(:no_collaborators)
    end

    it "renders 'not found' JSON when record not found" do
      stub(controller).index { raise ActiveRecord::RecordNotFound }
      get :index

      response.should be_not_found
      decoded_errors.record.should == "NOT_FOUND"
    end

    it "renders 'not found' JSON when HDFS directory is not found" do
      stub(controller).index { raise Hdfs::DirectoryNotFoundError }
      get :index

      response.should be_not_found
      decoded_errors.record.should == "NOT_FOUND"
    end

    it "renders 'invalid' JSON when record is invalid" do
      invalid_record = User.new
      invalid_record.password = "1"
      invalid_record.valid?
      stub(controller).index { raise ActiveRecord::RecordInvalid.new(invalid_record) }
      get :index
      response.should be_unprocessable
      decoded_errors.fields.username.BLANK.should == {}
    end

    it "renders string-based validation messages, when provided" do
      invalid_record = User.new
      invalid_record.errors.add(:username, :generic, :message => "some error")
      stub(controller).index { raise ActiveRecord::RecordInvalid.new(invalid_record) }
      get :index

      response.should be_unprocessable
      decoded_errors.fields.username.GENERIC.message.should == "some error"
    end

    it "returns error 422 when a Greenplum Connection error occurs" do
      error = PostgresLikeConnection::DatabaseError.new(StandardError.new('oops'))
      stub(error).error_type { :SOME_ERROR_TYPE }
      stub(controller).index { raise error }

      get :index

      response.should be_unprocessable
      decoded_errors.record.should == "SOME_ERROR_TYPE"
      decoded_errors.message.should == 'oops'
    end

    it "returns error 404 when a Hdfs Connection error occurs" do
      error = HdfsDataset::HdfsContentsError.new(StandardError.new('oops'))
      stub(controller).index { raise error }

      get :index

      response.should be_not_found
      decoded_errors.record.should == "HDFS_QUERY_ERROR"
      decoded_errors.message.should == 'oops'
    end

    it "returns error 422 when a data source driver error occurs" do
      error = DataSourceConnection::DriverNotConfigured.new('Oracle')
      stub(controller).index { raise error }

      get :index

      response.should be_unprocessable
      decoded_errors.record.should == "DATA_SOURCE_DRIVER_NOT_CONFIGURED"
      decoded_errors.data_source.should == 'Oracle'
    end

    it "returns error 422 when a Postgres error occurs" do
      stub(controller).index { raise ActiveRecord::JDBCError.new("oops") }

      get :index

      response.should be_unprocessable
      decoded_errors.fields.general.GENERIC.message.should == 'oops'
    end

    it "returns error 422 when a QueryError occurs" do
      stub(controller).index { raise DataSourceConnection::QueryError.new("broken!") }

      get :index

      response.should be_unprocessable
      decoded_errors.fields.query.INVALID.message.should == "broken!"
    end

    it "returns error 503 when an SearchExtensions::SolrUnreachable error is raised" do
      stub(controller).index { raise SearchExtensions::SolrUnreachable }

      get :index

      response.code.should == "503"
      decoded_errors.service.should == "SOLR_UNREACHABLE"
    end

    it "returns error 422 when a SunspotError occurs" do
      stub(controller).index { raise SunspotError.new("sunspot error") }

      get :index

      response.should be_unprocessable
      decoded_errors.fields.general.GENERIC.message.should == "sunspot error"
    end

    it "returns error 422 when a SunspotError occurs" do
      stub(controller).index { raise ModelMap::UnknownEntityType.new("Invalid entity type") }

      get :index

      response.should be_unprocessable
      decoded_errors.fields.general.GENERIC.message.should == "Invalid entity type"
    end

    it "returns error 403 when a PostgresLikeConnection::SqlPermissionDenied occurs" do
      stub(controller).index { raise PostgresLikeConnection::SqlPermissionDenied.new("SqlPermissionDenied error") }

      get :index

      response.should be_forbidden
      decoded_errors.message.should == "SqlPermissionDenied error"
      decoded_errors.type.should == "PostgresLikeConnection::SqlPermissionDenied"
    end

    it "returns error 403 when a DataSourceConnection::InvalidCredentials occurs" do
      data_source = data_sources(:default)
      stub(controller).index { raise DataSourceConnection::InvalidCredentials.new(data_source) }

      get :index

      response.code.should == "403"
      decoded_errors.model_data["id"].should == data_source.id
      decoded_errors.model_data["entity_type"].should == data_source.class.name.underscore
      decoded_errors.record.should == "INVALID_CREDENTIALS"
    end

    describe "when an access denied error is raised" do
      let(:object_to_present) { data_sources(:default) }
      let(:exception) { Allowy::AccessDenied.new('', 'action', object_to_present) }

      before do
        log_in users(:owner)
        stub(controller).index { raise exception }
      end

      it "returns a status of 403" do
        get :index
        response.should be_forbidden
      end

      it "presents the forbidden variant of the model" do
        mock(Presenter).present(anything, anything, hash_including(:forbidden => true))
        get :index
      end
    end
  end

  describe "#require_admin" do
    controller do
      before_filter :require_admin

      def index
        head :ok
      end
    end

    before do
      log_in user
    end

    context "when user has no admin rights" do
      let(:user) { users(:no_collaborators) }

      it "returns error 403" do
        get :index
        response.should be_forbidden
      end
    end

    context "when user has admin rights" do
      let(:user) { users(:admin) }

      it "returns success" do
        get :index
        response.should be_ok
      end
    end
  end

  describe "#current_user" do
    controller do
      def index
        render :text => current_user.present? ? current_user.id : nil
      end
    end

    let(:user) { users(:no_collaborators) }

    context 'the user is logged in' do
      before do
        log_in user
      end

      it "returns the user based on the session's user id" do
        get :index
        response.body.should == user.id.to_s
      end

      it 'returns nil when sent an invalid session_id param (csrf bypass attempt)' do
        get :index, :session_id => 'invalid'
        response.body.should == ' '
      end

      it 'returns nil when sent an empty session_id param (csrf bypass attempt)' do
        get :index, :session_id => ''
        response.body.should == ' '
      end
    end

    it "returns nil when there is no session_id stored in the session" do
      session[:chorus_session_id] = nil
      get :index
      response.body.should == ' '
    end

    it "returns nil when there is no session with the session_id" do
      session[:chorus_session_id] = -1
      get :index
      response.body.should == ' '
    end

    it "sets the user when session_id is sent" do
      session_object = Session.new
      session_object.user = user
      session_object.save(:validate => false)
      get :index, :session_id => session_object.session_id
      response.body.should == user.id.to_s
    end

    it "does not set the user when session_id is blank" do
      get :index, :session_id => ''
      response.body.should == ' '
    end
  end

  describe "#present" do
    controller do
      def index
        present object_to_present
      end
    end

    before do
      stub(controller).object_to_present { object_to_present }
      log_in users(:no_collaborators)
    end

    context "with a single model" do
      let(:object_to_present) { users(:owner) }

      it "sets the response to a hash of the model" do
        get :index
        decoded_response.username.should == object_to_present.username
      end
    end

    context "with a paginated collection" do

      let(:object_to_present) do
        User.paginate(:per_page => 2, :page => 1)
      end

      it "sets the response to an array with a hash for each model in current page" do
        get :index
        decoded_response.length.should == 2
        decoded_response[0].username.should == object_to_present[0].username
      end

      it "adds pagination" do
        get :index
        user_count = User.count
        page_count = (user_count/2.0).ceil
        decoded_pagination.page.should == 1
        decoded_pagination.per_page.should == 2
        decoded_pagination.total.should == page_count
        decoded_pagination.records.should == user_count
      end

      context "with a per_page of zero" do
        let(:object_to_present) do
          User.paginate(:per_page => 0, :page => 1)
        end

        it "omits the total pages in the response" do
          get :index

          decoded_pagination.total.should be_nil
        end
      end
    end
  end

  describe "session expiration" do
    controller do
      def index
        head :ok
      end
    end

    before do
      log_in users(:default)
    end

    context "with a fresh session" do
      it "tells the session to update its expiration" do
        any_instance_of(Session) do |s|
          mock(s).update_expiration!
        end
        get :index
        response.should be_success
      end
    end

    context "with an expired session" do
      before do
        any_instance_of(Session) do |s|
          stub(s).expired? { true }
        end
      end

      it "returns 'unauthorized'" do
        get :index
        response.code.should == "401"
      end
    end
  end

  describe "#head :ok" do
    controller do
      def index
        head :ok
      end
    end

    before do
      log_in users(:no_collaborators)
    end

    context "when the request is for application/json" do
      it "renders an empty hash" do
        request.env['HTTP_ACCEPT'] = 'application/json, text/javascript, */*'
        get :index
        response.body.should == '{}'
      end
    end

    context "when the request is not for application/json" do
      it "renders an empty hash" do
        request.env['CONTENT_TYPE'] = nil
        get :index
        response.body.should == ' '
      end
    end
  end
end
