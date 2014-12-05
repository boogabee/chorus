require 'spec_helper'

describe OrphanCleaner do
  describe 'clean' do
    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).running?
      end
    end

    context 'for hdfs data sources' do
      let(:hdfs) { hdfs_data_sources(:hadoop) }

      it 'removes orphaned hdfs entries' do
        entries = hdfs.hdfs_entries
        hdfs.destroy

        expect {
          OrphanCleaner.clean
        }.to change(entries, :count).to(0)
      end

      it 'removes orphaned hdfs datasets' do
        datasets = HdfsDataset.where(hdfs_data_source_id: hdfs.id)
        hdfs.update_attribute :deleted_at, Time.now

        expect {
          OrphanCleaner.clean
        }.to change(datasets, :count).to(0)
      end
    end

    context 'for gpdb data source' do
      let(:data_source) { data_sources(:owners) }

      it 'removes orphaned gpdb databases' do
        databases = data_source.databases
        data_source.destroy

        expect {
          OrphanCleaner.clean
        }.to change(databases, :count).to(0)
      end

      it 'removes orphaned schemas' do
        schema_ids = data_source.schema_ids
        data_source.destroy
        data_source.databases.update_all(:deleted_at => Time.now)

        expect {
          OrphanCleaner.clean
        }.to change(Schema.where(:id => schema_ids), :count).to(0)
      end

      it 'removes orphaned datasets' do
        dataset_ids = data_source.dataset_ids
        data_source.destroy
        data_source.schemas.update_all(:deleted_at => Time.now)

        expect {
          OrphanCleaner.clean
        }.to change(Dataset.where(:id => dataset_ids), :count).to(0)
      end
    end

    context 'for oracle source' do
      let(:data_source) { data_sources(:oracle) }

      it 'removes orphaned schemas' do
        schemas = data_source.schemas
        data_source.destroy

        expect {
          OrphanCleaner.clean
        }.to change(schemas, :count).to(0)
      end

      it 'removes orphaned datasets' do
        dataset_ids = data_source.dataset_ids
        data_source.destroy
        data_source.schemas.update_all(:deleted_at => Time.now)

        expect {
          OrphanCleaner.clean
        }.to change(Dataset.where(:id => dataset_ids), :count).to(0)
      end
    end
  end
end
