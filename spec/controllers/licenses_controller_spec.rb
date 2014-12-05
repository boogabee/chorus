require 'spec_helper'

describe LicensesController do
  let(:user) { users(:owner) }
  let(:license) { License.instance }
  let(:sample) do
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

  before do
    log_in user
    stub.proxy(license).[](anything)
    sample.each do |key, value|
      stub(license).[](key) { value }
    end
  end

  describe '#show' do
    it 'presents the license info' do
      get :show
      response.should be_ok

      sample.each do |key, value|
        decoded_response[key].should == (value.is_a?(Date) ? value.to_s : value)
      end
    end

    generate_fixture 'license.json' do
      get :show
    end
  end
end
