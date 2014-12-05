require 'spec_helper'

describe UserUpdateService do
  let(:admin) { users(:admin) }
  let(:user) { users(:the_collaborator) }

  describe '#update!' do
    context 'when the actor is an admin' do
      let(:service) { UserUpdateService.new(actor: admin, target: user) }
      let(:params) { {:admin => true, :developer => true, :first_name => 'Joey'} }

      it 'updates params including admin and developer' do
        service.update!(params)
        user.admin?.should be_true
        user.developer?.should be_true
      end

      context 'when the target is an admin' do
        let(:service) { UserUpdateService.new(actor: admin, target: admin) }

        context 'when the target admin owns a job in a workspace of which they are not a member' do
          let(:workspace) { workspaces(:public_with_no_collaborators) }
          before do
            FactoryGirl.create(:job, :owner => admin, :workspace => workspace)
          end

          context 'removing their admin status' do
            it 'should transfer job ownership to the workspace owner' do
              job = Job.last
              expect {
                service.update!(:admin => false)
                job.reload
              }.to change(job, :owner).from(admin).to(workspace.owner)
            end
          end

          context 'updating the user but not their admin status' do
            it 'should not change any job ownership' do
              job = Job.last
              expect {
                service.update!(:first_name => 'StillAdmin')
                job.reload
              }.not_to change(job, :owner)
            end
          end
        end

        context 'when the admin owns a job in a workspace of which they are a member' do
          let(:workspace) { workspaces(:public_with_no_collaborators) }
          before do
            FactoryGirl.create(:job, :owner => admin, :workspace => workspace)
            workspace.members << admin
          end

          context 'removing their admin status' do
            it 'should not transfer job ownership to the workspace owner' do
              job = Job.last
              expect {
                service.update!(:admin => false)
                job.reload
              }.not_to change(job, :owner)
            end
          end
        end
      end
    end

    context 'when the actor is not an admin' do
      let(:service) { UserUpdateService.new(actor: user, target: user) }
      let(:params) { {:admin => true, :developer => true, :first_name => 'Joey'} }

      before do
        service.update!(params)
      end

      it 'updates the target user params' do
        user.first_name.should == 'Joey'
      end

      it 'does not update admin or developer' do
        user.admin?.should be_false
        user.developer?.should be_false
      end
    end
  end
end
