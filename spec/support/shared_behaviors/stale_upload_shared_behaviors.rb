shared_examples_for 'an upload that goes stale' do

  describe 'delete old files' do
    let(:clazz) { described_class }
    let(:instance_of_clazz) { clazz.first }
    let(:hour_limit) { 1 }
    let(:time_cutoff) { hour_limit.hour.ago }

    context 'when config variable is set' do
      before do
        stub(ChorusConfig.instance).[]('delete_unimported_csv_files_after_hours') { hour_limit }
      end

      it 'removes files older than delete_unimported_csv_files_after_hours from the app config' do
        instance_of_clazz.update_attribute(:created_at, time_cutoff - 5.minutes)
        clazz.delete_old_files!
        clazz.find_by_id(instance_of_clazz.id).should be_nil
      end

      it 'does not remove files more recent than delete_unimported_csv_files_after_hours from the app config' do
        instance_of_clazz.update_attribute(:created_at, time_cutoff + 5.minutes)
        clazz.delete_old_files!
        clazz.find_by_id(instance_of_clazz.id).should_not be_nil
      end
    end

    context 'when config variable is not set' do
      before do
        stub(ChorusConfig.instance).[]('delete_unimported_csv_files_after_hours') { nil }
      end

      it 'does not remove any files' do
        expect { clazz.delete_old_files! }.not_to change { clazz.count }
      end
    end
  end

end
