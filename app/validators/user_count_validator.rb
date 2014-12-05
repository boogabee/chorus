class UserCountValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license_validation(:limit_user_count?) do |license|
      record.errors.add(:user, :license_limit_exceeded) if User.count >= license[:collaborators]
    end
  end

end
