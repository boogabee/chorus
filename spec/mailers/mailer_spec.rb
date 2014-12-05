require "spec_helper"

describe Mailer do
  describe '#notify' do
    let(:event) { Events::JobSucceeded.last }
    let(:recipient) { users(:the_collaborator) }
    let(:sent_mail) { Mailer.notify(recipient, event) }
    let(:subject) { event.header }

    it_behaves_like 'a sent mail with subject and recipient'

    context "the event is a JobSucceeded/JobFailed" do
      it "has a body with the job name and workspace name" do
        encoded_body = sent_mail.body.encoded
        encoded_body.should include event.job.name
        encoded_body.should include event.workspace.name
      end

      it "includes all of the job task results" do
        encoded_body = sent_mail.body.encoded
        results = event.job_result.job_task_results
        results.length.should be > 0
        results.each do |result|
          encoded_body.should include result.name
        end
      end

      describe 'successful jobs' do
        it "says the job succeeded" do
          sent_mail.body.encoded.should include 'succeeded'
        end
      end

      describe 'failing jobs' do
        let(:event) { Events::JobFailed.last }

        it "says the job failed" do
          sent_mail.body.encoded.should include 'failed'
        end
      end
    end
  end

  describe '#chorus_expiring' do
    let(:recipient) { users(:admin) }
    let(:subject) { 'Your Chorus license is expiring.' }
    let(:expiration) { 2.weeks.from_now.to_date }
    let(:vendor) { 'alpine' }
    let(:license) { License.new :expires => expiration, :vendor => vendor }
    let(:sent_mail) { Mailer.chorus_expiring(recipient, license) }

    it_behaves_like 'a sent mail with subject and recipient'

    it 'includes the expiration message' do
      encoded_body = sent_mail.body.encoded
      encoded_body.should match(/Your Chorus license will expire on #{expiration}/)
      encoded_body.should match(/Please contact Alpine/)
    end

    context 'pivotal branding' do
      let(:vendor) { 'pivotal' }

      it 'includes the expiration message' do
        encoded_body = sent_mail.body.encoded
        encoded_body.should match(/Your Chorus license will expire on #{expiration}/)
        encoded_body.should match(/Please contact Pivotal/)
      end
    end
  end
end
