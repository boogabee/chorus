require 'spec_helper'

describe GpfdistTableCopier, :greenplum_integration do
  let(:data_source_account) { GreenplumIntegration.real_account }
  let(:user) { data_source_account.owner }
  let(:database) { GpdbDatabase.find_by_name_and_data_source_id(GreenplumIntegration.database_name, GreenplumIntegration.real_data_source) }
  let(:schema_name) { 'test_gpfdist_schema' }
  let(:schema) { database.schemas.find_by_name(schema_name) }
  let(:destination_table_fullname) { %Q{"#{sandbox.name}"."#{destination_table_name}"}}

  let(:db_options) { database.connect_with(data_source_account).db_options.merge({:logger => Rails.logger }) } # enable logging

  let(:source_database_url) { database.connect_with(data_source_account).db_url }
  let(:source_database) { Sequel.connect(source_database_url, db_options) }

  let(:destination_database_url) { database.connect_with(data_source_account).db_url }
  let(:destination_database) { Sequel.connect(destination_database_url, db_options) }

  let(:source_table) { "candy" }
  let(:source_table_fullname) { "\"#{schema_name}\".\"#{source_table}\"" }
  let(:destination_table_name) { "dst_candy" }
  let(:table_def) { '"id" numeric(4,0),
                     "name" character varying(255),
                      "id2" integer,
                      "id3" integer,
                      "date_test" date,
                      "fraction" double precision,
                      "numeric_with_scale" numeric(4,2),
                      "time_test" time without time zone,
                      "time_with_precision" time(3) without time zone,
                      "time_with_zone" time(3) with time zone,
                      "time_stamp_with_precision" timestamp(3) with time zone,
                      PRIMARY KEY("id2", "id3", "id")'.tr("\n","").gsub(/\s+/, " ").strip }
  let(:distrib_def) { "" }
  let(:import) { imports(:now) }
  let(:source_dataset) { schema.datasets.find_by_name(source_table) }
  let(:pipe_name) { Time.current.to_i.to_s + "_pipe_id" }
  let(:options) do
    {
        :source => source_dataset,
        :destination_schema => sandbox,
        :destination_table_name => destination_table_name,
        :user => user,
        :sample_count => sample_count,
        :truncate => truncate,
        :pipe_name => pipe_name
    }.merge(extra_options)
  end
  let(:truncate) { false }
  let(:sample_count) { nil }
  let(:extra_options) { {} }
  let(:copier) { GpfdistTableCopier.new(options) }
  let(:sandbox) { schema }

  def setup_data
    with_database_connection(source_database_url) do |connection|
      execute(connection, "delete from #{source_table_fullname};")
      execute(connection, "insert into #{source_table_fullname}(id, name, id2, id3) values (1, 'marsbar', 3, 5);")
      execute(connection, "insert into #{source_table_fullname}(id, name, id2, id3) values (2, 'kitkat', 4, 6);")
    end
    with_database_connection(destination_database_url) do |connection|
      execute(connection, "drop table if exists #{destination_table_fullname};")
    end
  end

  before do
    stub.proxy(ChorusConfig.instance).[](anything)
    stub(ChorusConfig.instance).[](/^gpfdist\./) do |key|
      case key.sub(/^gpfdist\./, '')
        when "data_dir"
          '/tmp'
        when "write_port"
          ENV['CI_GPFDIST_WRITE_PORT'] || "8000"
        when "read_port"
          ENV['CI_GPFDIST_READ_PORT'] || "8001"
        when "url"
          Socket.gethostname
        when "ssl.enabled"
          false
      end
    end
  end
  
  it 'uses gpfdist if the gpfdist.ssl.enabled configuration is false (no in the test environment)' do
    copier.gpfdist_protocol.should == 'gpfdist'
  end

  context "run" do
    def destination_table_exists?
      destination_database.table_exists?(Sequel.qualify(sandbox.name, destination_table_name))
    end

    after do
      execute(source_database_url, "delete from #{source_table_fullname};")
      execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
    end

    context "into a new table" do
      before do
        setup_data
      end

      it "creates a new pipe and runs it" do
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 2
      end

      context "can import from schemas that are named something different" do
        let(:sandbox) { database.schemas.find_by_name('public') }

        it "runs" do
          copier.start
          get_rows(destination_database_url, "SELECT * FROM public.dst_candy").length.should == 2
        end
      end

      it "should only have the first row when limiting rows to 1" do
        extra_options.merge!(:sample_count => 1)
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 1
      end

      it "doesn't hang gpfdist with a row limit of 0, by treating the source like an empty table" do
        extra_options.merge!(:sample_count => 0)
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 0
      end

      it "drops the newly created table when the write does not complete" do
        any_instance_of(GpfdistTableCopier) do |pipe|
          stub(pipe).write_data { }
        end
        stub(copier).semaphore_timeout { 1000 }

        destination_table_exists?.should be_false
        expect { copier.start }.to raise_error(TableCopier::ImportFailed)
        destination_table_exists?.should be_false
      end

      it "drops the newly created table when the read does not complete" do
        any_instance_of(GpfdistTableCopier) do |pipe|
          stub(pipe).reader_loop { }
        end
        stub(copier).semaphore_timeout { 1000 }

        destination_table_exists?.should be_false
        expect { copier.start }.to raise_error(TableCopier::ImportFailed)
        destination_table_exists?.should be_false
      end
    end

    context "into an existing table" do
      before do
        setup_data
        execute(source_database_url, "create table #{destination_table_fullname}(#{table_def});")
      end

      it "should truncate the existing table if the truncate flag is set" do
        extra_options.merge!(:truncate => true)
        execute(source_database_url, "insert into #{destination_table_fullname}(id, name, id2, id3) values (21, 'kitkat-1', 41, 61);")
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 1
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 2
      end

      it "does not truncate the data when truncate is false" do
        extra_options.merge!(:truncate => false)
        execute(source_database_url, "insert into #{destination_table_fullname}(id, name, id2, id3) values (21, 'kitkat-1', 41, 61), (22, 'kitkat-2', 42, 62);")
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 2
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 4
      end

      it "does not drop the table when the import does not complete" do
        any_instance_of(GpfdistTableCopier) do |pipe|
          stub(pipe).writer_sql { "select pg_sleep(1)" }
        end
        destination_table_exists?.should be_true
        expect { copier.start }.to raise_error(TableCopier::ImportFailed)
        destination_table_exists?.should be_true
      end
    end

    context "from a chorus view" do
      let(:source_dataset) do
        cv = FactoryGirl.build :chorus_view, :name => "a_chorus_view", :query => "select * from #{source_table}",
                           :schema => schema, :workspace => workspaces(:public)
        cv.save(:validate => false)
        cv
      end

      before do
        setup_data
      end

      it "works like a normal dataset import" do
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 2
      end
    end

    context "with distribution key" do
      let(:distrib_def) { 'DISTRIBUTED BY("id2", "id3")' }

      before do
        setup_data
      end
      it "should move data from candy to dst_candy and have the correct primary key and distribution key" do
        copier.start

        with_database_connection(destination_database_url) do |connection|
          get_rows(connection, "SELECT * FROM #{destination_table_fullname}").length.should == 2

          primary_key_sql = <<-SQL
            SELECT attname
            FROM   (SELECT *, generate_series(1, array_upper(a, 1)) AS rn
            FROM  (SELECT conkey AS a
            FROM   pg_constraint where conrelid = '#{destination_table_fullname}'::regclass and contype='p'
            ) x
            ) y, pg_attribute WHERE attrelid = '#{destination_table_fullname}'::regclass::oid AND a[rn] = attnum ORDER by rn;
          SQL

          rows = get_rows(connection, primary_key_sql)

          rows[0][:attname].should == 'id2'
          rows[1][:attname].should == 'id3'
          rows[2][:attname].should == 'id'

          distribution_key_sql = <<-SQL
            SELECT attname
            FROM   (SELECT *, generate_series(1, array_upper(a, 1)) AS rn
            FROM  (SELECT attrnums AS a
            FROM   gp_distribution_policy where localoid = '#{destination_table_fullname}'::regclass
            ) x
            ) y, pg_attribute WHERE attrelid = '#{destination_table_fullname}'::regclass::oid AND a[rn] = attnum ORDER by rn;
          SQL

          # defaults to the first one
          rows = get_rows(connection, distribution_key_sql)
          rows[0][:attname].should == 'id2'
          rows[1][:attname].should == 'id3'
        end
      end
    end

    context "create external table does not succeed" do
      it "does not hang" do
        setup_data
        stub(copier).gpfdist_protocol { 'gpfdistinvalid' }
        expect { copier.start }.to raise_error(TableCopier::ImportFailed)
      end
    end

    context "tables have weird characters" do
      let(:source_table) { "2candy" }
      let(:destination_table_name) { "2dst_candy" }

      it "single quotes table and schema names if they have weird chars" do
        setup_data
        copier.start
        get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 2
      end
    end
  end

  context "when the source table is empty" do
    before do
      execute(source_database_url, "delete from #{source_table_fullname};")
      execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
    end

    after do
      execute(source_database_url, "delete from #{source_table_fullname};")
      execute(destination_database_url, "drop table if exists #{destination_table_fullname};")
    end

    it "simply creates the dst table if the source table is empty (no gpfdist used)" do
      copier.start

      get_rows(destination_database_url, "SELECT * FROM #{destination_table_fullname}").length.should == 0
    end
  end

  it "does not use special characters in the pipe names" do
    copier.pipe_name.should match(/^[_a-zA-Z\d]+$/)
  end

  it "includes the pipe_name attribute in the pipe_name" do
    copier.pipe_name.should match(/pipe_\d+_\d+_#{pipe_name}$/)
  end

  describe "cancel" do
    let(:user) { import.user }
    let(:source_connection) { Object.new }
    let(:write_connection) { Object.new }

    before do
      stub(GpfdistTableCopier).log.with_any_args
      stub(import.source_dataset).connect_as(user) { source_connection }
      stub(import.schema).connect_as(user) { write_connection }
      stub(source_connection).running?.with_any_args { true }
      stub(write_connection).running?.with_any_args { true }
      stub(source_connection).kill.with_any_args
      stub(write_connection).kill.with_any_args
    end

    it 'kills the source connection' do
      mock(source_connection).kill("pipe%_#{import.created_at.to_i}_#{import.id}_w")

      GpfdistTableCopier.cancel(import)
    end

    it 'kills the write connection' do
      mock(write_connection).kill("pipe%_#{import.created_at.to_i}_#{import.id}_r")

      GpfdistTableCopier.cancel(import)
    end

    it 'removes the named pipe from disk' do
      dir = ChorusConfig.instance['gpfdist.data_dir']
      FileUtils.mkdir_p dir
      pipe_file = File.join(dir, "pipe_with_some_extra_stuff_#{import.created_at.to_i}_#{import.id}")
      FileUtils.touch pipe_file
      GpfdistTableCopier.cancel(import)
      File.exists?(pipe_file).should be_false
    end
  end

  def execute(database, sql_command, schema = schema, method = :run)
    with_database_connection(database) do |connection|
      connection.run("set search_path to #{schema.name}, public;")
      connection.send(method, sql_command)
    end
  end

  def get_rows(database, sql_command, schema = schema)
    execute(database, sql_command, schema, :fetch).all
  end

  def with_database_connection(database, &block)
    if database.is_a?(String)
      Sequel.connect(database, db_options, &block)
    else
      block.call database
    end
  rescue Exception
    raise
  end
end
