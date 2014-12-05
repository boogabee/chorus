require 'spec_helper'

describe DataDownloadsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#download_data" do
    it "responds with 200 for valid request" do

      post :download_data,
            :content => "I am CSV",
            :mime_type => "text/csv",
            :filename => "myDownload.csv"

      response.code.should == "200"
      response.headers['Content-Type'].should == 'text/csv'
      response.headers['Content-Disposition'].should == 'attachment; filename="myDownload.csv"'
      response.body.should == "I am CSV"
    end

    it_behaves_like "prefixed file downloads" do
      let(:do_request) { post :download_data,
                              :content => "I am CSV",
                              :mime_type => "text/csv",
                              :filename => "myDownload.csv" }
      let(:expected_filename) { "myDownload.csv" }
    end
  end
end
