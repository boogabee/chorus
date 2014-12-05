require 'spec_helper'

describe PgViewAccess do
  let(:context) { Object.new }
  let(:access) { PgViewAccess.new(context)}
  let(:dataset) { datasets(:pg_view) }

  it_behaves_like 'dataset access control'
end
