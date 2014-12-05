require 'spec_helper'

describe CsvFile do
  describe "validations" do
    let(:default_params) { {
        :contents => StringIO.new('a,b,c'),
        :column_names => ['a', 'b', 'c'],
        :types => ['a', 'b', 'c'],
        :delimiter => '"',
        :to_table => "new_table",
        :has_header => false,
        :new_table => false,
        :truncate => false,
        :user => users(:owner),
        :workspace => workspaces(:public)
    }}

    it "is not ready to import if it is missing a setting" do
      [:column_names, :types, :delimiter, :has_header, :to_table].each do |param|
        c = CsvFile.new(default_params.reject{ |k,v| k == param }, :without_protection => true)
        c.ready_to_import?.should be_false
      end
    end

    it "is valid when tab is the delimiter" do
      c = CsvFile.new(default_params.merge(:delimiter => "\t"), :without_protection => true)
      c.ready_to_import?.should be_true
    end

    it "requires a non-nil delimiter" do
      c = CsvFile.new(default_params.merge(:delimiter => nil), :without_protection => true)
      c.ready_to_import?.should be_false
    end

    it "requires a non-empty delimiter" do
      c = CsvFile.new(default_params.merge(:delimiter => ''), :without_protection => true)
      c.ready_to_import?.should be_false
    end

    it "does not validate the size of the CSV file if the file is not user uploaded" do
      any_instance_of(Paperclip::StringioAdapter) do |a|
        stub(a).size { ChorusConfig.instance['file_sizes_mb']['csv_imports'].megabytes + 1.megabyte }
      end
      c = CsvFile.new(default_params.merge(:user_uploaded => false), :without_protection => true)
      c.valid?.should be_true
    end

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:workspace) }

    context "validate file sizes" do
      let(:max_csv_import_size) {ChorusConfig.instance['file_sizes_mb']['csv_imports']}

      it { should validate_attachment_size(:contents).less_than(max_csv_import_size.megabytes) }
    end
  end

  it_behaves_like 'an upload that goes stale'

  describe '#escaped_column_names' do
    let(:csv_file) { FactoryGirl.build(:csv_file, :column_names => ['where', 'order', 'select'])}

    it 'returns escaped column names' do
      csv_file.escaped_column_names.should == %w{"where" "order" "select"}
    end
  end
  
  describe "#table_already_exists" do
    let(:csv_file) { csv_files(:default) }
    let(:user) { csv_file.user }
    let(:schema) { schemas(:public) }
    let(:workspace) { csv_file.workspace }
    let(:table_name) { "foo_bar" }
    subject { csv_file.table_already_exists(table_name) }

    before do
      workspace.sandbox = schema
      workspace.save!
      connection = Object.new
      stub(workspace.sandbox).connect_as(user) { connection }
      stub(connection).table_exists? { table_exists }
    end

    context "when the table exists" do
      let(:table_exists) { true }

      it { should be_true }
    end

    context "when the table does not exist" do
      let(:table_exists) { false }

      it { should be_false }
    end
  end
end
