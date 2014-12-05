require 'spec_helper'

resource 'License' do
  let(:user) { users(:admin) }
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

  get '/license' do
    before do
      log_in user
      sample.each do |key, value|
        stub(License.instance).[](key) { value }
      end
    end

    example_request 'Get license info' do
      status.should == 200
    end
  end
end
