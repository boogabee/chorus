require 'spec_helper'

describe PgTableAccess do
  let(:context) { Object.new }
  let(:access) { PgTableAccess.new(context)}
  let(:dataset) { datasets(:pg_table) }

  it_behaves_like 'dataset access control'
end
