require 'spec_helper'

describe PgView do
  it_behaves_like 'a dataset view' do
    let(:view) { datasets(:pg_view) }
  end
end
