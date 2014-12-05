require 'spec_helper'

describe DatasetDownloadsController do
  it_behaves_like "an action that requires authentication", :get, :show, :dataset_id => -1

  describe "#show" do
    let(:user) { users(:the_collaborator) }
    let(:table) { datasets(:table) }
    let(:data_source_account) { table.data_source.account_for_user!(user) }

    let(:connection) {
      object = Object.new
      stub(table).connect_as(satisfy { |arg| arg.id == user.id && arg.class == User }) { object }
      object
    }

    let(:streamer_options) do
      {
        :row_limit => 12,
        :quiet_null => true,
        :rescue_connection_errors => true
      }
    end

    let(:params) do
      {
          :dataset_id => table.to_param,
          :row_limit => "12",
      }
    end

    before do
      stub(Dataset).find(table.id.to_s) { table }

      streamer = Object.new
      mock(SqlStreamer).new(table.all_rows_sql(12), connection, hash_including(streamer_options)) { streamer }
      mock(streamer).enum { "i am the enum" }

      log_in user
    end

    it_behaves_like "prefixed file downloads" do
      let(:do_request) { get :show, params }
      let(:expected_filename) { "#{table.name}.csv" }
    end

    context "with valid file content" do
      it "should response with success" do
        get :show, params
        response.code.should == "200"
      end
      it "streams the data into the template" do
        get :show, params
        response.body.should == 'i am the enum'
      end

      it "sets stream to true which sets the correct headers" do
        get :show, params
        response.headers["Cache-Control"].should == 'no-cache'
        response.headers["Transfer-Encoding"].should == 'chunked'
      end

      context "when header is false" do
        let(:streamer_options) do
          {
              :row_limit => 12,
              :header => false,
              :quiet_null => true,
              :rescue_connection_errors => true
          }
        end

        it "should get a headerless enumerator" do
          get :show, params.merge(:header => 'false')
          response.body.should == "i am the enum"
        end
      end
    end
  end
end