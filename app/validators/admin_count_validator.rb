class AdminCountValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license_validation(:limit_user_count?) do |license|
      if record.admin? && (User.admin_count + num_new(record)) > license[:admins]
        record.errors.add(:admin, :license_limit_exceeded)
      end
    end
  end

  def num_new(record)
    record.admin_changed? ? 1 : 0
  end
end
