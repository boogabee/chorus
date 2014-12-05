require 'spec_helper'

describe Kaggle::MessagesController, :kaggle_api => true do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#create" do
    let(:params) { {
        "reply_to" => "chorusadmin@example.com",
        "html_body" => "Example Body\nwith two lines",
        "subject" => "Example Subject",
        "recipient_ids" => ["6732"],
        "workspace_id" => "1"
    } }
    it_behaves_like "an action that requires authentication", :post, :create, :workspace_id => '-1'

    it "returns 201 when the message sends" do
      mock(Kaggle::API).send_message(
          hash_including('replyTo' => 'chorusadmin@example.com',
                         'userId' => ['6732'],
                         'subject' => 'Example Subject',
                         'apiKey' => ChorusConfig.instance['kaggle.api_key']
       ))

      post :create, params
      response.should be_success
    end

    it "formats the message to appear correctly in emails" do
      mock(Kaggle::API).send_message(hash_including('htmlBody' => 'Example Body<br>with two lines'))
      post :create, params
    end

    context 'when the message send fails' do
      before do
        mock(Kaggle::API).send_message(anything) {
          raise Kaggle::API::MessageFailed.new 'This is an arbitrary error message'
        }
      end

      it "presents an error json" do
        post :create, params
        response.code.should == '422'
        decoded_response = JSON.parse(response.body)
        error_message = decoded_response['errors']['fields']['general']['GENERIC']['message']
        error_message.should == 'This is an arbitrary error message'
      end
    end
  end
end