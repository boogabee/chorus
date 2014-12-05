require 'spec_helper'

describe JobBoss do
  describe '#run' do
    let!(:job1) { FactoryGirl.create(:job) }
    let!(:job2) { FactoryGirl.create(:job) }
    let!(:job3) { FactoryGirl.create(:job) }

    before do
      stub(Job).ready_to_run { [job1, job2] }
      stub(Job).awaiting_stop { [job2, job3] }
    end

    it 'finds the jobs that are ready to run and runs them' do
      mock(job1).enqueue
      mock(job2).enqueue
      dont_allow(job3).enqueue

      JobBoss.run
    end

    context 'when a job is invalid' do
      before do
        stub(job2).valid? { false }
      end

      it 'disables the jobs that are invalid instead of running them' do
        mock(job1).enqueue
        mock(job2).disable
        dont_allow(job2).enqueue
        dont_allow(job3).enqueue

        JobBoss.run
      end

      it 'creates a JobDisabled event' do
        expect { JobBoss.run }.to change(Events::JobDisabled, :count).by(1)
      end

      it 'creates a notification for the job owner' do
        expect { JobBoss.run }.to change(Notification, :count).by(1)
        notification = Notification.last
        notification.event.should == Events::Base.last
        notification.recipient.should == job2.owner
      end

      it 'does not blow up if an error is raised' do
        stub(Job).ready_to_run { [job1, job2, job3] }
        mock(job2).disable { raise }
        mock(job1).enqueue
        mock(job3).enqueue

        JobBoss.run
      end
    end

    it 'finds the jobs that have stalled while stopping and idles them' do
      dont_allow(job1).idle
      mock(job2).idle
      mock(job3).idle

      JobBoss.run
    end
  end
end
