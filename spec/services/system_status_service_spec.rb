require 'spec_helper'
require 'timecop'

describe SystemStatusService do

  include_context 'license hash'
  let(:mock_license) { License.new license_hash }
  let(:service) { SystemStatusService.new(Date.current, mock_license) }

  describe '.refresh' do
    it 'creates a Checker with the current time and license and refreshes it' do
      Timecop.freeze do
        mock.proxy(SystemStatusService).new(Date.current, License.instance)
        any_instance_of(SystemStatusService) do |service|
          mock(service).refresh
        end

        SystemStatusService.refresh
      end
    end
  end

  describe '.latest' do
    context 'when a SystemStatus exists' do
      before do
        FactoryGirl.create(:system_status)
      end

      it 'returns SystemStatus.last' do
        SystemStatus.last.should == SystemStatusService.latest
      end
    end

    context 'when no SystemStatuses exist' do
      before do
        mock(SystemStatus.last) { nil }
      end

      it 'refreshes to create one' do
        mock.proxy(SystemStatusService).refresh.once
        SystemStatusService.latest
      end
    end
  end

  describe '#refresh' do
    it 'creates a new SystemStatus' do
      expect {
        service.refresh
      }.to change(SystemStatus, :count).by(1)
    end

    it 'transfers the results to the SystemStatus model' do
      stub(service).users_exceeded? { true }
      stub(mock_license).expired?(is_a(Date)) { true }
      service.refresh
      ss = SystemStatus.last
      ss.user_count_exceeded?.should be_true
      ss.expired?.should be_true
    end

    context 'when the license expires in less than 2 weeks' do
      let(:expires) { 13.days.from_now.to_date }
      before { stub(mock_license).expires? { true } }

      it 'should notify all admin users' do
        service.refresh
        ActionMailer::Base.deliveries.map(&:to).reduce(&:+).should =~ User.admin.map(&:email)
        ActionMailer::Base.deliveries.first.subject.should == 'Your Chorus license is expiring.'
      end
    end
  end

  describe '#users_exceeded?' do
    before do
      stub(User).admin_count { 1 }
      stub(User).developer_count { 2 }
      stub(User).count { 5 }
    end

    context 'when license#limit_user_count? is true' do
      before do
        mock(mock_license).limit_user_count? { true }
      end

      it 'returns false if no counts are exceeded' do
        service.users_exceeded?.should be_false
      end

      it 'returns true if admins is exceeded' do
        stub(User).admin_count { 11 }
        service.users_exceeded?.should be_true
      end

      it 'returns true if developers is exceeded' do
        stub(User).admin_count { 101 }
        service.users_exceeded?.should be_true
      end

      it 'returns true if collaborators is exceeded' do
        stub(User).count { 1001 }
        service.users_exceeded?.should be_true
      end
    end

    context 'license#limit_user_count? is true' do
      before do
        mock(mock_license).limit_user_count? { false }
      end

      it 'returns false without checking' do
        mock(User).admin_count.never
        mock(User).developer_count.never
        mock(User).count.never
        service.users_exceeded?.should be_false
      end
    end
  end
end
