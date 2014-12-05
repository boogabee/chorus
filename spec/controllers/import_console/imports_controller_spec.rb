require 'spec_helper'

describe ImportConsole::ImportsController do
  render_views

  let(:user) { users(:admin) }

  before do
    log_in user
  end

  describe "#index" do
    context "with an schema import (for oracle)" do
      let(:pending_import) { imports(:oracle) }

      before do
        Import.where(:finished_at => nil).each do |import|
          import.update_attribute(:finished_at, Time.now)
        end
        pending_import.update_attribute(:finished_at, nil)
      end

      it "returns success" do
        get :index
        response.should be_success
      end
    end

    context "when there are imports pending" do
      let(:pending_import) { imports(:one) }

      before do
        Import.where(:finished_at => nil).each do |import|
          import.update_attribute(:finished_at, Time.now)
        end
        pending_import.update_attribute(:finished_at, nil)
      end

      it "returns success" do
        get :index
        response.should be_success
      end

      it "fetches a list of pending imports" do
        get :index
        assigns(:imports).map(&:id).should == [pending_import.id]
      end

      context 'when gpfdist is not configured' do
        before do
          stub.proxy(ChorusConfig.instance).[](anything)
          stub.proxy(ChorusConfig.instance).[](/gpfdist/) { nil }
        end

        it 'does not blow up' do
          get :index
          response.should be_success
        end
      end
    end

    context "when the user is not an admin" do
      let(:user) { users(:the_collaborator) }

      it "returns forbidden" do
        get :index
        response.code.should == "403"
      end
    end

    context "when the user is not logged in" do
      before do
        log_out
      end

      it "redirects to the application root" do
        get :index
        response.should redirect_to ":#{ChorusConfig.instance['server_port']}/"
      end
    end
  end
end


