require 'spec_helper'

describe JdbcTablePresenter, :type => :view do
  let(:table) { datasets(:jdbc_table) }
  let(:presenter) { JdbcTablePresenter.new(table, view) }

  before(:each) do
    set_current_user(users(:admin))
  end

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }

    it 'sets the object type to TABLE' do
      hash[:object_type].should == 'TABLE'
    end
  end

  it_behaves_like 'jdbc dataset presenter', :jdbc_table
end
