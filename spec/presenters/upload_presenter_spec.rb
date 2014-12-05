require 'spec_helper'

describe UploadPresenter, :type => :view do
  let(:file) { test_file('test.csv', 'text/csv') }
  let(:upload) { FactoryGirl.create(:upload, :contents => file) }
  let(:presenter) { UploadPresenter.new(upload, view) }

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }

    it 'includes the right keys' do
      hash[:id].should == upload.id
      hash[:file_name].should == upload.contents_file_name
    end
  end
end
