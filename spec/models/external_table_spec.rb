require 'spec_helper'

describe ExternalTable do
  let(:hdfs_entry) { hdfs_entries(:hdfs_file) }
  let(:sandbox_data_source) { databases(:default).data_source }
  let(:connection) { Object.new }
  let(:params) do
    {
        :sandbox_data_source => sandbox_data_source,
        :connection => connection,
        :schema_name => 'public',
        :column_names => ['field1', 'field2'],
        :column_types => ['text', 'text'],
        :name => 'foo',
        :entry_or_dataset => hdfs_entry,
        :delimiter => ','
    }
  end

  it "should validate the presence of attributes" do
    [:column_names, :column_types, :name, :entry_or_dataset].each do |a|
      e = ExternalTable.new(params.merge(a => nil))
      e.should have_error_on(a)
    end
  end

  it "should be valid for any delimiters including the space character" do
    [',', ' ', "\t"].each do |d|
      e = ExternalTable.new(params.merge(:delimiter => d))
      e.should be_valid
    end
  end

  it "should be invalid for no delimiter" do
    ['', 'ABCD'].each do |d|
      e = ExternalTable.new(params.merge(:delimiter => d))
      e.should_not be_valid
      e.errors.first.should == [:delimiter, [:EMPTY, {}]]
    end
  end

  it "should save successfully" do
    e = ExternalTable.new(params)
    mock(connection).create_external_table(
      :table_name => "foo",
      :columns => "field1 text, field2 text",
      :location_url => "gphdfs://#{hdfs_entry.hdfs_data_source.host}:#{hdfs_entry.hdfs_data_source.port}#{hdfs_entry.path}",
      :delimiter => ","
    )
    e.save
  end

  it "should not save if invalid" do
    e = ExternalTable.new(params.merge(:name => nil))
    dont_allow(connection).create_external_table
    e.save.should be_false
    e.should have_error_on(:name).with_message(:blank)
  end

  describe 'location url' do
    context "when the database is HAWQ" do
      before do
        sandbox_data_source.update_attribute(:is_hawq, true)
      end

      it "should construct a url with the pxf:// protocol" do
        e = ExternalTable.new(params)
        mock(connection).create_external_table(anything) do |table_params|
          table_params[:location_url].should == "pxf://#{hdfs_entry.hdfs_data_source.host}:50070" + hdfs_entry.path + '?Fragmenter=HdfsDataFragmenter&Accessor=TextFileAccessor&Resolver=TextResolver'
        end
        e.save
      end
    end

    context "when the database is not HAWQ" do
      it "should construct a url with the gphdfs:// protocol" do
        e = ExternalTable.new(params)
        mock(connection).create_external_table(anything) do |table_params|
          table_params[:location_url].should == "gphdfs://#{hdfs_entry.hdfs_data_source.host}:#{hdfs_entry.hdfs_data_source.port}" + hdfs_entry.path
        end
        e.save
      end
    end
  end

  context "when saving fails" do
    it "adds table already exists error when the table already exists" do
      e = ExternalTable.new(params)
      stub(connection).create_external_table.with_any_args do
        raise PostgresLikeConnection::DatabaseError.new(StandardError.new())
      end

      e.save.should be_false
      e.should have_error_on(:name).with_message(:TAKEN)
    end
  end

  context "creating an external table from a directory" do
    it "create the table" do
      e = ExternalTable.new(params.merge(:file_pattern => "*.csv"))
      mock(connection).create_external_table(
        :table_name => "foo",
        :columns => "field1 text, field2 text",
        :location_url => "gphdfs://#{hdfs_entry.hdfs_data_source.host}:#{hdfs_entry.hdfs_data_source.port}#{hdfs_entry.path}/*.csv",
        :delimiter => ","
      )
      e.save
    end
  end
end
