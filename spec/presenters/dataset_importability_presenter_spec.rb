require 'spec_helper'

describe DatasetImportabilityPresenter, :type => :view do
  let(:importability) { Object.new }
  let(:presenter) { DatasetImportabilityPresenter.new(importability, view) }
  let(:hash) { presenter.to_hash }

  before do
    stub(importability).importable? { invalid_columns.empty? }
    stub(importability).invalid_columns { invalid_columns }
    stub(importability).supported_column_types { ["SOME", "SUPPORTED", "COLUMNS"]}
  end

  context "when the dataset it importable" do
    let(:invalid_columns) { [] }

    it "only includes importability in the response" do
      hash[:importability].should == true
      hash.keys.should_not include('invalid_columns')
      hash.keys.should_not include('supported_columns')
    end
  end

  context "when the dataset is not importable" do
    let(:invalid_columns) {[
       {column_name: "a", column_type: "potato"},
       {column_name: "b", column_type: "celery"}
    ]}

    it "includes importability, invalid columns, and supported columns" do
      hash[:importability].should == false
      hash[:invalid_columns].should == ["a (potato)", "b (celery)"]
      hash[:supported_column_types].should == ["SOME", "SUPPORTED", "COLUMNS"]
    end
  end
end