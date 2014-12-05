require 'spec_helper'

describe OracleTableAccess do
  let(:context) { Object.new }
  let(:access) { OracleTableAccess.new(context)}
  let(:dataset) { datasets(:oracle_table) }

  it_behaves_like 'dataset access control'
end
