module Events
  class ImportCreatedBase < Base
    after_update :create_dataset_activity

    def create_dataset_activity
      if changed_attributes.with_indifferent_access.include? :target2_id
        Activity.create!(:event => self, :entity => dataset)
      end
    end

    def self.find_for_import(import)
      reference_id = import.id
      reference_type = Import.name

      possible_events = filter_for_import_events(import)

      # optimized to avoid fetching all events since the intended event is almost certainly the last event
      while event = possible_events.last
        return event if event.reference_id == reference_id && event.reference_type == reference_type
        possible_events.pop
      end
    end
  end
end