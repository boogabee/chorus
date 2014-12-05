require 'spec_helper'

describe Alpine::CredentialsController do
  let(:data_source) { data_sources(:owners) }
  let(:user) { users(:owner) }
  let(:account) { data_source.account_for_user(user) }

  describe '#show' do
    before do
      log_in user
      stub(request).remote_ip { '127.0.0.1' }
      stub(request).remote_addr { '::1' }
    end

    context 'when alpine is enabled' do
      before do
        stub(License.instance).workflow_enabled? { true }
      end

      it 'returns the username and password for the user for the data source' do
        get :show, :data_source_id => data_source.id
        response.should be_success
        decoded_response.username.should == account.db_username
        decoded_response.password.should == account.db_password
      end

      context 'for a shared data source' do
        let(:data_source) { data_sources(:shared) }
        let(:user) { users(:default) }
        let(:account) { data_source.owner_account }

        it "returns the owner's username and password" do
          account.owner.should_not == user
          get :show, :data_source_id => data_source.id
          response.should be_success
          decoded_response.username.should == account.db_username
          decoded_response.password.should == account.db_password
        end
      end

      context 'when the user does not have an account' do
        let(:user) { users(:not_a_member) }

        it 'returns 404 when the user does not have an account' do
          get :show, :data_source_id => data_source.id
          response.should be_not_found
        end
      end

      describe 'for local requests' do
        [
            '127.0.0.1',
            '::1',
            '0:0:0:0:0:0:0:1%0',
            '::ffff:127.0.0.1'
        ].each do |ip|
          it "works for #{ip}" do
            stub(request).remote_ip { ip }
            stub(request).remote_addr { ip }
            get :show, :data_source_id => data_source.id
            response.should be_success
          end
        end
      end
    end

    context 'when alpine is disabled' do
      before do
        stub(License.instance).workflow_enabled? { false }
      end

      it 'returns not found' do
        get :show, :data_source_id => data_source.id
        response.should be_not_found
      end
    end
  end
end
