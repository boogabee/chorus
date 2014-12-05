class ImportCanceler
  def self.run
    new.run
  end

  def run
    while true
      cancel_imports
      sleep 5
    end
  end

  def cancel_imports
    imports_awaiting_cancel.each do |import|
      pa "Cancelling Import: #{import.id} (#{import.class})"
      import.cancel false
      pa "Done Cancelling Import: #{import.id}"
    end
  end

  def imports_awaiting_cancel
    Import.where(:success => nil).
        where(Import.arel_table[:started_at].not_eq(nil)).
        where(Import.arel_table[:canceled_at].not_eq(nil))
  end
end