require 'spec_helper'

describe JobPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:options) { {} }
  let(:workspace) { job.workspace }
  let(:presenter) { JobPresenter.new(job, view, options) }

  before { set_current_user(user) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }
    let(:keys) { [
        :workspace, :name, :last_run, :next_run, :interval_unit, :interval_value,
        :enabled, :status, :id, :end_run, :time_zone, :is_deleted, :last_run_failed,
        :success_notify, :failure_notify, :success_recipients, :failure_recipients
    ] }
    let(:expensive_keys) {[
        :tasks, :owner
    ]}

    describe "list_view" do
      let(:options) { {list_view: true} }
      let(:hash) { presenter.to_hash }


      it "includes the right keys" do
        keys.each { |key| hash.should have_key(key) }
        expensive_keys.each {|key| hash.should_not have_key(key)}
      end
    end

    context "not list_view" do
      let(:hash) { presenter.to_hash }

      it "includes the right keys" do
        (keys + expensive_keys).each { |key| hash.should have_key(key) }
      end

      it "presents next run and last_run as iso8601 strings with timezone" do
        job.update_attribute(:last_run, 'Tue, 30 Jul 2013 12:27:27 UTC +00:00')
        job.update_attribute(:next_run, 'Wed, 31 Jul 2013 12:27:27 UTC +00:00')
        job.update_attribute(:time_zone, 'Alaska')
        hash[:last_run].to_i.should == DateTime.parse('Tue, 30 Jul 2013 12:27:27 UTC +00:00').to_i
        hash[:next_run].to_i.should == DateTime.parse('Wed, 31 Jul 2013 12:27:27 UTC +00:00').to_i

        hash[:last_run].iso8601.should == '2013-07-30T04:27:27-08:00'
        hash[:next_run].iso8601.should == '2013-07-31T04:27:27-08:00'
      end

      context "for a job to be run on demand" do
        let(:job) { jobs(:on_demand) }

        it "presents coal" do
          hash[:next_run].should be_nil
        end
      end
    end
  end
end
