require 'spec_helper'

describe Dataset do
  let(:schema) { schemas(:default) }
  let(:other_schema) { schemas(:other_schema) }
  let(:dataset) { datasets(:table) }

  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnDataset.create!({
                                        :actor => users(:owner),
                                        :dataset => model,
                                        :body => "This is the body"
                                    }, :as => :create)
    end

    let!(:model) { dataset }
  end
  it_should_behave_like "taggable models", [:datasets, :table]

  describe "associations" do
    it { should belong_to(:scoped_schema).class_name('Schema') }
    it { should have_many :activities }
    it { should have_many :events }
    it { should have_many :notes }
    it { should have_many :comments }

    describe "#schema" do
      it "returns the schema even if it is deleted" do
        any_instance_of(GreenplumConnection) do |data_source|
          stub(data_source).running? { false }
        end
        dataset.schema.should == schema
        schema.destroy
        dataset.reload.schema.should == schema
      end
    end

    describe 'associable?' do
      let(:dataset) { Dataset.new }

      it 'raises NotImplemented' do
        expect { dataset.associable? }.to raise_error(NotImplementedError)
      end
    end
  end

  describe "workspace association" do
    let(:workspace) { workspaces(:public) }
    let(:dataset) { datasets(:source_table) }
    before do
      dataset.bound_workspaces = []
      dataset.bound_workspaces << workspace
    end

    it "can be bound to workspaces" do
      dataset.bound_workspaces.should include workspace
    end
  end

  describe "validations" do
    it { should validate_presence_of :scoped_schema }
    it { should validate_presence_of :name }

    it "validates uniqueness of name in the database" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      expect {
        duplicate_dataset.save!(:validate => false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "does not bother validating uniqueness of name in the database if the record is deleted" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      duplicate_dataset.deleted_at = Time.current
      duplicate_dataset.save(:validate => false).should be_true
    end

    it "validates uniqueness of name, scoped to schema id" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.name = dataset.name
      duplicate_dataset.should have_at_least(1).error_on(:name)
      duplicate_dataset.schema = other_schema
      duplicate_dataset.should have(:no).errors_on(:name)
    end

    it "validates uniqueness of name, scoped to type" do
      duplicate_dataset = ChorusView.new
      duplicate_dataset.name = dataset.name
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.should have(:no).errors_on(:name)
    end

    it "validate uniqueness of name, scoped to deleted_at" do
      duplicate_dataset = GpdbTable.new
      duplicate_dataset.name = dataset.name
      duplicate_dataset.schema = dataset.schema
      duplicate_dataset.should have_at_least(1).error_on(:name)
      duplicate_dataset.deleted_at = Time.current
      duplicate_dataset.should have(:no).errors_on(:name)
    end
  end

  describe ".with_name_like" do
    it "matches anywhere in the name, regardless of case" do
      dataset.update_attributes!({:name => "amatCHingtable"}, :without_protection => true)

      Dataset.with_name_like("match").count.should == 1
      Dataset.with_name_like("MATCH").count.should == 1
    end

    it "returns all objects if name is not provided" do
      Dataset.with_name_like(nil).count.should == Dataset.count
    end

    it "does not treat special characters as wildcards" do
      dataset.update_attributes!({:name => "amat_%ingtable"}, :without_protection => true)

      Dataset.with_name_like("t_%i").count.should == 1
      #Dataset.with_name_like("_m").count.should == 0
    end

    it "is a joinable query" do
      # Regression test in case query provides ambiguous column references
      workspace = workspaces(:public)

      expect {
        workspace.datasets(users(:owner), {
            :name_filter => 'match',
            :database_id => workspace.sandbox.database
        })
      }.not_to raise_error
    end
  end

  describe ".filter_by_name" do
    let(:second_dataset) {
      GpdbTable.new({:name => 'rails_only_table', :scoped_schema => schema}, :without_protection => true)
    }
    let(:dataset_list) {
      [dataset, second_dataset]
    }

    it "matches anywhere in the name, regardless of case" do
      dataset.update_attributes!({:name => "amatCHingtable"}, :without_protection => true)

      Dataset.filter_by_name(dataset_list, "match").count.should == 1
      Dataset.filter_by_name(dataset_list, "MATCH").count.should == 1
    end

    it "returns all objects if name is not provided" do
      Dataset.filter_by_name(dataset_list, nil).count.should == dataset_list.count
    end
  end

  describe "#all_rows_sql" do
    it "returns the correct sql" do
      dataset = datasets(:table)
      dataset.all_rows_sql.strip.should == %Q{SELECT * FROM "#{dataset.name}"}
    end

    context "with a limit" do
      it "uses the limit" do
        dataset = datasets(:table)
        dataset.all_rows_sql(10).should match "LIMIT 10"
      end
    end
  end

  describe ".find_and_verify_in_source" do
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:table) }

    before do
      stub(Dataset).find(dataset.id) { dataset }
    end

    context 'when it exists in the source database' do
      before do
        mock(dataset).verify_in_source(user) { true }
      end

      it 'returns the dataset' do
        described_class.find_and_verify_in_source(dataset.id, user).should == dataset
      end
    end

    context 'when it does not exist in Greenplum' do
      before do
        mock(dataset).verify_in_source(user) { false }
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.find_and_verify_in_source(dataset.id, user)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "caching" do
    before do
      mock(Rails.cache).fetch({:model_class => "GpdbTable", :model_id => dataset.id, :key => cache_key}, :expires_in => 60.seconds)
    end

    describe "#column_data" do
      let(:cache_key) { :column_data }

      it "uses caching" do
        dataset.column_data
      end
    end

    describe "#table_description" do
      let(:cache_key) { :table_description }

      it "uses caching" do
        dataset.table_description
      end
    end
  end

  describe "destroy" do
    context "with imports" do
      let(:dataset) { datasets(:table) }

      it "cancels the import" do
        unfinished_imports = dataset.imports.unfinished
        stub(dataset.imports).unfinished { unfinished_imports }
        unfinished_imports.should_not be_empty
        unfinished_imports.each do |import|
          mock(import).cancel(false, "Source/Destination of this import was deleted")
        end
        dataset.destroy
      end
    end
  end

  describe "list_order" do
    # postgres loves to order by update order, it's like that
    it "sorts by id as a secondary sort, and not by update order" do
      Dataset.order("id desc").all.each_with_index do |dataset, i|
        Dataset.where(:id => dataset.id).update_all(:name => 'billy', :schema_id => i)
      end
      ids = Dataset.list_order.collect &:id
      ids.should == ids.sort
      User.create
    end
  end

  it_should_behave_like "taggable models", [:datasets, :table]

  it_behaves_like 'a soft deletable model' do
    let(:model) { dataset }
  end
end