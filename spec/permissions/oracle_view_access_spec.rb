require 'spec_helper'

describe OracleViewAccess do
  let(:context) { Object.new }
  let(:access) { OracleViewAccess.new(context)}
  let(:dataset) { datasets(:oracle_view) }

  it_behaves_like 'dataset access control'
end
