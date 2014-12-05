module LicenseValidations

  def with_license_validation(validation)
    yield License.instance if License.instance.send(validation)
  end

end
