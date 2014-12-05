require 'spec_helper'

describe JdbcViewAccess do
  let(:context) { Object.new }
  let(:access) { JdbcViewAccess.new(context)}
  let(:dataset) { datasets(:jdbc_view) }

  it_behaves_like 'dataset access control'
end
