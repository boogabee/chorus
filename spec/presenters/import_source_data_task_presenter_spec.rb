require 'spec_helper'

describe ImportSourceDataTaskPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:job_task) { job_tasks(:isdt) }
  let(:presenter) { ImportSourceDataTaskPresenter.new(job_task, view) }

  before(:each) do
    set_current_user(user)
  end

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:id, :job, :action, :index, :name, :source_id, :destination_id, :source_name, :destination_name, :row_limit, :truncate] }

    it "includes the right keys" do
      keys.each do |key|
        hash.should have_key(key)
      end
    end

    it "finds the source_name for the task's source and presents it" do
      hash[:source_name].should == job_task.payload.source.name
    end

    it "presents 'truncate' as a boolean, not a string" do
      hash[:truncate].should be_instance_of(TrueClass)
    end

    context 'when the payload source dataset has been deleted' do
      before do
        job_task.payload.source.destroy
        job_task.reload
      end

      it 'presents an invalid task' do
        hash[:name].should == '[invalid task]'
      end
    end
  end
end
