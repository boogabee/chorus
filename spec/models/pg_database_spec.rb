require 'spec_helper'

describe PgDatabase do
  context 'associations' do
    it { should have_many(:schemas).class_name('PgSchema') }

    it 'has many datasets' do
      databases(:pg).datasets.should include(datasets(:pg_table))
    end
  end

  it_should_behave_like 'something that can go stale' do
    let(:model) { databases(:pg) }
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { databases(:pg) }
  end

  it_behaves_like 'a well-behaved database' do
    let(:database) { databases(:pg) }
  end

  it_behaves_like 'an index-able database' do
    let(:database) { databases(:pg) }
  end
end
