require 'spec_helper'

describe GpdbDatabase do
  it_should_behave_like 'something that can go stale' do
    let(:model) { databases(:default) }
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { databases(:default) }
  end

  it_behaves_like 'a well-behaved database' do
    let(:database) { databases(:default) }
  end

  it_behaves_like 'an index-able database' do
    let(:database) { databases(:default) }
  end

  describe "validations" do
    it 'has a valid factory' do
      FactoryGirl.build(:gpdb_database).should be_valid
    end

    it { should validate_presence_of(:name) }

    it 'does not allow strange characters in the name' do
      ['/', '&', '?'].each do |char|
        new_database = FactoryGirl.build(:gpdb_database, :name =>"schema#{char}name")
        new_database.should have_error_on(:name)
      end
    end

    describe 'name uniqueness' do
      let(:existing) { databases(:default) }

      context 'in the same data_source' do
        it 'does not allow two databases with the same name' do
          new_database = FactoryGirl.build(:gpdb_database,
                                           :name => existing.name,
                                           :data_source => existing.data_source)
          new_database.should have_error_on(:name).with_message(:taken)
        end
      end

      context 'in a different data_source' do
        it 'allows same names' do
          new_database = FactoryGirl.build(:gpdb_database, :name => existing.name)
          new_database.should be_valid
        end
      end
    end
  end

  context "refresh using a real greenplum data_source", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }

    it "sorts the database by name in ASC order" do
      results = GpdbDatabase.refresh(account)
      result_names = results.map { |db| db.name.downcase.gsub(/[^0-9A-Za-z]/, '') }
      result_names.should == result_names.sort
    end
  end

  context "association" do
    it { should have_many(:schemas).class_name('GpdbSchema') }

    it "has many datasets" do
      databases(:default).datasets.should include(datasets(:table))
    end
  end

  describe ".create_schema" do
    let(:connection) { Object.new }
    let(:database) { databases(:default) }
    let(:user) { users(:owner) }
    let(:schema_name) { "stuff" }

    before do
      stub(database).connect_as(user) { connection }
      stub(Schema).refresh.with_any_args { database.schemas.create(:name => schema_name) }
    end

    it "should create the schema" do
      mock(connection).create_schema(schema_name)
      expect {
        database.create_schema(schema_name, user).name.should == schema_name
      }.to change(GpdbSchema, :count).by(1)
    end

    context "when the schema is invalid" do
      before do
        any_instance_of(GpdbSchema) do |schema|
          stub(schema).valid? { false }
        end
      end

      it "should not create the database" do
        dont_allow(connection).create_schema.with_any_args
        expect do
          expect do
            database.create_schema(schema_name, user)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.not_to change(GpdbSchema, :count)
      end
    end
  end
end
