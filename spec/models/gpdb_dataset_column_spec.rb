require 'spec_helper'

describe GpdbDatasetColumn do
  describe ".columns_for" do
    subject { described_class.columns_for(account, dataset) }

    let(:connection) { Object.new }
    let(:account) { Object.new }
    let(:dataset) { OpenStruct.new({:name => 'hiya_bob', :query_setup_sql => "select yo from bar;", :column_type => "GpdbDatasetColumn"}) }

    let(:column_with_stats) do
      [
          {
              :attname => 'id',
              :format_type => 'integer',
              :description => nil,
              :null_frac => 0.0,
              :n_distinct => 2,
              :most_common_vals => '{0, 1}',
              :most_common_freqs => '{0, 1}',
              :histogram_bounds => '{0, 1}',
              :reltuples => 2
          },
          {
              :attname => 'column1',
              :format_type => 'integer',
              :description => 'comment on column1',
              :null_frac => 0.0,
              :n_distinct => 2,
              :most_common_vals => '{0, 1}',
              :most_common_freqs => '{0, 1}',
              :histogram_bounds => '{0, 1}',
              :reltuples => 2
          },
          {
              :attname => 'timecolumn',
              :format_type => 'timestamp without time zone',
              :description => 'comment on timecolumn',
              :null_frac => 0.0,
              :n_distinct => 2,
              :most_common_vals => '{0, 1}',
              :most_common_freqs => '{0, 1}',
              :histogram_bounds => '{0, 1}',
              :reltuples => 2
          }
      ]
    end

    before do
      stub(connection).column_info(dataset.name, dataset.query_setup_sql) { column_with_stats }
      stub(dataset).connect_with(account) { connection }
    end

    it "returns dataset columns" do
      subject.first.should be_a GpdbDatasetColumn
    end

    it "gets the column information for table users" do
      subject.count.should == 3
      column1 = subject[1]

      column1.name.should eq('column1')
      column1.data_type.should eq('integer')
      column1.description.should == 'comment on column1'
      column1.ordinal_position.should eq(2)
    end

    it "gets the column stats for table users" do
      column1 = subject[1]
      column1_stats = column1.statistics

      column1_stats.should be_a GpdbColumnStatistics
      column1_stats.null_fraction.should == 0.0
      column1_stats.number_distinct.should == 2
      column1_stats.common_values.should =~ %w(0 1)
    end

    it 'has the correct column type for time values' do
      time_column = subject.last
      time_column.simplified_type.should == :datetime
      time_column.should be_number_or_time
    end
  end

  describe "#number_or_time?" do
    it "is true if it is a numeric column" do
      described_class.new(:name => 'col', :data_type => "integer").should be_number_or_time
      described_class.new(:name => 'col', :data_type => "numeric").should be_number_or_time
      described_class.new(:name => 'col', :data_type => "double precision").should be_number_or_time
    end

    it "is true if it is a time column" do
      described_class.new(:name => 'col', :data_type => "date").should be_number_or_time
      described_class.new(:name => 'col', :data_type => "time with time zone").should be_number_or_time
      described_class.new(:name => 'col', :data_type => "timestamp with time zone").should be_number_or_time
    end

    it "is false otherwise" do
      described_class.new(:name => 'col', :data_type => "text").should_not be_number_or_time
    end
  end

  describe "#simplified_type" do
    subject { described_class.new(:name => 'col', :data_type => type_string) }

    def self.it_simplifies_type(type, simplified_type)
      context "with a '#{type}' column" do
        let(:type_string) { type }
        its(:simplified_type) { should == simplified_type }
      end
    end

    it_simplifies_type("complex", nil)
    it_simplifies_type("numeric", :decimal)
    it_simplifies_type("integer[]", :string)
    it_simplifies_type("bigint", :integer)
    it_simplifies_type("bit(5)", :string)
    it_simplifies_type("bit varying(10)", :string)
    it_simplifies_type("boolean", :boolean)
    it_simplifies_type("box", :string)
    it_simplifies_type("bytea", :binary)
    it_simplifies_type("character varying(10)", :string)
    it_simplifies_type("character(10)", :string)
    it_simplifies_type("cidr", :string)
    it_simplifies_type("circle", :string)
    it_simplifies_type("date", :date)
    it_simplifies_type("double precision", :float)
    it_simplifies_type("inet", :string)
    it_simplifies_type("integer", :integer)
    it_simplifies_type("interval", :string)
    it_simplifies_type("lseg", :string)
    it_simplifies_type("macaddr", :string)
    it_simplifies_type("money", :decimal)
    it_simplifies_type("numeric(5,5)", :decimal)
    it_simplifies_type("path", :string)
    it_simplifies_type("point", :string)
    it_simplifies_type("polygon", :string)
    it_simplifies_type("real", :float)
    it_simplifies_type("smallint", :integer)
    it_simplifies_type("text", :text)
    it_simplifies_type("time without time zone", :time)
    it_simplifies_type("time with time zone", :time)
    it_simplifies_type("timestamp without time zone", :datetime)
    it_simplifies_type("timestamp with time zone", :datetime)
  end
end
