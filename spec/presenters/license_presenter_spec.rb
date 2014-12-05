require 'spec_helper'

describe LicensePresenter, :type => :view do
  let(:license) { License.new license_hash }
  let(:presenter) { LicensePresenter.new(license, view, {}) }
  let(:hash) { presenter.to_hash }

  let(:license_hash) do
    {
      :admins => 5,
      :developers => 10,
      :collaborators => 100,
      :level => 'triple-platinum',
      :vendor => 'openchorus',
      :organization_uuid => 'o-r-g',
      :expires => Date.parse('2014-07-31')
    }
  end

  describe 'to_hash' do
    it 'includes the license key/value pairs' do
      license_hash.each do |key, value|
        hash[key].should == value
      end
    end

    it 'includes the work flow configuration' do
      stub(license).workflow_enabled? { true }
      hash[:workflow_enabled].should be_true
    end

    it 'includes the branding' do
      stub(license).branding { 'brands' }
      hash[:branding].should == 'brands'
    end

    it 'includes the search configuration' do
      stub(license).limit_search? { true }
      hash[:limit_search].should be_true
    end

    it 'includes the advisor now configuration' do
      stub(license).advisor_now_enabled? { true }
      hash[:advisor_now_enabled].should be_true
    end

    it 'includes limit_workspace_membership' do
      stub(license).limit_workspace_membership? { true }
      hash[:limit_workspace_membership].should be_true
    end

    it 'includes limit_milestones' do
      stub(license).limit_milestones? { true }
      hash[:limit_milestones].should be_true
    end

    it 'includes limit_jobs' do
      stub(license).limit_jobs? { true }
      hash[:limit_jobs].should be_true
    end

    it 'includes home_page' do
      stub(license).home_page { 'CustomHomePage' }
      hash[:home_page].should == 'CustomHomePage'
    end

    it 'includes limit_sandboxes?' do
      stub(license).limit_sandboxes? { true }
      hash[:limit_sandboxes].should be_true
    end
  end
end
