require 'spec_helper'

resource "Kaggle", :kaggle_api => true do
  include KaggleSpecHelpers

  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }
  let(:workspace_id) { workspace.id }

  before do
    log_in user
  end

  get "/kaggle/users" do
    parameter :'filters[]', "Array of filters, each with the pipe-separated format: 'filter|comparator|value'"

    let(:'filters[]') { "rank|greater|1" }

    example "Get a list of Kaggle users" do
      stub(Kaggle::API).users(anything) do
        kaggle_users_api_result
      end

      do_request(:'filters[]' => [])
      status.should == 200
    end
  end

  post "/kaggle/messages" do
    parameter :reply_to, "Email address of sender"
    parameter :subject, "Subject of message to Kaggle user"
    parameter :html_body, "Body of message to Kaggle user"
    parameter :'recipient_ids[]', "Kaggle user ids of recipients"

    let(:reply_to) { "user@chorus.com" }
    let(:subject) { 'Please analyze my data' }
    let(:html_body) { 'I have a lot of data that needs to be analyzed.' }
    let(:recipient_ids) { ['63766', '63767'] }

    required_parameters :reply_to, :subject, :html_body, :'recipient_ids[]'

    example "Send a message to Kaggle users" do
      VCR.use_cassette('kaggle_message_success', :tag => :filter_kaggle_api_key) do
        do_request(:reply_to => reply_to, :subject => subject, :html_body => html_body, :recipient_ids => recipient_ids)
        status.should == 201
      end
    end
  end
end
