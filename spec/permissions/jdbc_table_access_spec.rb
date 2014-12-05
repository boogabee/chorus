require 'spec_helper'

describe JdbcTableAccess do
  let(:context) { Object.new }
  let(:access) { JdbcTableAccess.new(context)}
  let(:dataset) { datasets(:jdbc_table) }

  it_behaves_like 'dataset access control'
end
