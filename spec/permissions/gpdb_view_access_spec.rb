require 'spec_helper'

describe GpdbViewAccess do
  let(:context) { Object.new }
  let(:access) { GpdbViewAccess.new(context)}
  let(:dataset) { datasets(:view) }

  it_behaves_like 'dataset access control'
end
