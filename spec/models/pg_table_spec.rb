require 'spec_helper'

describe PgTable do
  it_behaves_like 'a dataset table' do
    let(:table) { datasets(:pg_table) }
  end
end
