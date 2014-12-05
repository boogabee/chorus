require 'spec_helper'

describe CsvCopier do
  let(:user) { "user guy" }
  let(:destination_schema) { schemas(:default) }
  let(:destination_table_name) { "new_user_guy_table" }
  let(:connection) { Object.new }
  let(:sample_count) { nil }
  let(:truncate) { false }
  let(:csv_file) { csv_files(:unimported) }
  let(:copier) do
    CsvCopier.new(
        {
            :source => csv_file,
            :destination_schema => destination_schema,
            :destination_table_name => destination_table_name,
            :user => user,
            :sample_count => sample_count,
            :truncate => truncate
        }
    )
  end

  before do
    stub(destination_schema).connect_as(user) { connection }
  end

  describe "initialize_destination_table" do
    subject { copier.initialize_destination_table }
    before do
      stub(connection).table_exists?(destination_table_name) { table_exists }
    end

    context "when the table doesn't exist" do
      let(:table_exists) { false }
      before do
        stub(csv_file).column_names { %w(foo bar baz quux quuux quuuux) }
        stub(csv_file).types { %w(text integer float date time timestamp) }
      end

      it "should create the table with the right columns" do
        mock(connection).create_table(destination_table_name, %Q|"foo" text, "bar" integer, "baz" float, "quux" date, "quuux" time, "quuuux" timestamp|, 'DISTRIBUTED RANDOMLY')
        subject
      end
    end
  end

  describe "run" do
    before do
      stub(java.io.FileReader).new(csv_file.contents.path) { 'I am a file reader!' }
    end

    it "should have the connection copy the file in" do
      mock(connection).copy_csv('I am a file reader!', destination_table_name, csv_file.column_names, csv_file.delimiter, csv_file.has_header)
      copier.run
    end

    it "should delete the csv file" do
      mock(connection).copy_csv.with_any_args
      copier.run
      CsvFile.find_by_id(csv_file.id).should be_nil
    end

    it "should delete the csv file when there is an error" do
      mock(connection).copy_csv.with_any_args { raise 'oops' }
      expect { copier.run }.to raise_error(TableCopier::ImportFailed)
      CsvFile.find_by_id(csv_file.id).should be_nil
    end
  end

  describe "validate!" do
    it "should raise when the csv file is not ready to import" do
      stub(csv_file).ready_to_import? { false }
      expect { copier.validate! }.to raise_error('CSV file cannot be imported')
    end
  end
end