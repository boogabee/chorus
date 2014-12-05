module StaleUpload
  extend ActiveSupport::Concern

  module ClassMethods
    def delete_old_files!
      age_limit = ChorusConfig.instance['delete_unimported_csv_files_after_hours']
      return unless age_limit
      where('created_at < ?', Time.current - age_limit.hours).destroy_all
    end
  end
end
