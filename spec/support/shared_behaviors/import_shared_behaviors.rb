shared_examples_for :import_generates_no_events do |trigger|
  it 'generates no new events or notifications' do
    expect {
      expect {
        send(trigger)
      }.not_to change(Events::Base, :count)
    }.not_to change(Notification, :count)
  end
end

shared_examples_for :import_generates_no_events_when_already_marked_as_passed_or_failed do |trigger|
  context 'when the import is already marked as passed' do
    before do
      import.success = true
      import.save!
    end
    it_behaves_like :import_generates_no_events, trigger
  end

  context 'when the import is already marked as failed' do
    before do
      import.success = false
      import.save!
    end
    it_behaves_like :import_generates_no_events, trigger
  end
end

shared_examples_for :import_succeeds do |trigger|
  context 'when import is successful' do
    it 'creates a success event and notification' do
      mock(import).create_passed_event_and_notification
      send(trigger)
    end

    it 'marks the import as success' do
      send(trigger)
      import.reload
      import.success.should be_true
      import.finished_at.should_not be_nil
    end

    it 'saves the dataset' do
      refreshed = false

      any_instance_of(Schema) do |schema|
        stub(schema).find_or_initialize_dataset.with_any_args { stub(Object.new).save { refreshed = true } }
      end
      send(trigger)
      refreshed.should be_true
    end

    it 'updates the destination dataset id' do
      send(trigger)
      import.reload
      import.success.should be_true
      import.destination_dataset_id.should_not be_nil
    end

    it 'sets the dataset attribute of the DATASET_IMPORT_CREATED event' do
      send(trigger)
      event = import_created_event.reload
      event.dataset.name.should == destination_table_name
      event.dataset.schema.should == sandbox
    end

    it_behaves_like :import_generates_no_events_when_already_marked_as_passed_or_failed, trigger

    context 'when dataset refresh fails' do
      before do
        any_instance_of(Schema) do |schema|
          stub(schema).refresh_datasets.with_any_args do
            raise ActiveRecord::JDBCError, 'refresh failed -- oh no!'
          end
          stub.proxy(schema).datasets do |datasets_relation|
            stub.proxy(datasets_relation).tables do |tables_relation|
              stub(tables_relation).find_by_name(destination_table_name) { nil }
            end
          end
        end
      end

      it 'still creates a destinationImportSuccess event with an empty dataset link' do
        expect {
          expect {
            send(trigger)
          }.not_to raise_error
        }.to change(import.success_event_class, :count).by(1)
        event = import.created_event_class.last
        event.dataset.should be_nil
      end
    end
  end

  context 'when the import created event cannot be found' do
    before do
      import_created_event.delete
    end

    it 'does not blow up' do
      expect {
        send(trigger)
      }.not_to raise_error
    end
  end
end

shared_examples_for :import_fails_with_message do |trigger, message|
  let(:expected_failure_message) { message }

  context 'when the import fails' do
    it 'creates' do
      mock(import).create_failed_event_and_notification(message)
      send(trigger)
    end

    it 'marks the import as failed' do
      send(trigger)
      import.reload
      import.success.should be_false
      import.finished_at.should_not be_nil
    end

    it_behaves_like :import_generates_no_events_when_already_marked_as_passed_or_failed, trigger
  end
end

shared_examples_for 'an importable dataset' do
  describe '#can_import_into' do
    context 'when tables have same column number, names and types' do
      let(:destination) { schema.datasets.find_by_name('view1') }

      it 'says tables are consistent' do
        source.can_import_into(destination).should be_true
      end
    end

    context 'when tables have the same column number and types, but different names' do
      let(:destination) { schema.datasets.find_by_name('different_names_table') }

      it 'says tables are not consistent' do
        source.can_import_into(destination).should be_false
      end
    end

    context 'when tables have same column number and names, but different types' do
      let(:destination) { schema.datasets.find_by_name('different_types_table') }

      it 'says tables are not consistent' do
        source.can_import_into(destination).should be_false
      end
    end

    context 'when tables have different number of columns' do
      let(:destination) { schema.datasets.find_by_name('master_table1') }

      it 'says tables are not consistent' do
        source.can_import_into(destination).should be_false
      end
    end
  end
end
