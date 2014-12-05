require 'spec_helper'

describe GpdbView do
  it_behaves_like 'a dataset view' do
    let(:view) { datasets(:view) }
  end
end
