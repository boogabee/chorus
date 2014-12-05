require 'spec_helper'

resource 'Uploads' do

  let(:user) { users(:owner) }

  before { log_in user }

  post '/uploads' do
    parameter :contents, 'Uploaded file'

    required_parameters :contents

    let(:contents) { Rack::Test::UploadedFile.new(File.expand_path('spec/fixtures/test.csv', Rails.root), 'text/csv') }

    example_request 'Upload a file' do
      status.should == 201
    end
  end
end
