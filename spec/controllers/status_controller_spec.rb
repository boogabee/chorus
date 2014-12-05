require 'spec_helper'

describe StatusController do
  describe '#show' do
    it 'should include the latest system status' do
      get :show
      response.code.should == '200'
      body = response.decoded_body
      body[:status].should == 'Chorus is running'
      body[:user_count_exceeded].should be_false
      body[:updated_at].should_not be_nil
    end

    generate_fixture 'status.json' do
      get :show
    end
  end
end
