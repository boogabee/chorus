class MemberCountValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license_validation(:limit_workspace_membership?) do |license|
      record.errors.add(:members, :license_limit_exceeded) if record.members.count > 1
    end
  end

end
