require 'spec_helper'

describe UploadsController do

  let(:user) { users(:owner) }
  let(:file) { test_file('test.csv', 'text/csv') }

  before { log_in user }

  describe '#create' do
    let(:params) { { :contents => file } }

    it 'saves an upload' do
      expect { post :create, params }.to change(Upload, :count).by(1)
    end

    it 'sets the upload file name and uploading user' do
      mock_present do |upload|
        upload.contents_file_name.should == 'test.csv'
        upload.user.id.should == user.id
      end

      post :create, params
    end

    it 'returns 201' do
      post :create, params
      response.should be_success
      response.code.should == '201'
    end

    generate_fixture 'upload.json' do
      post :create, params
    end
  end
end
