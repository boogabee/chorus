class ErrorPresenter

  def initialize(errors)
    @errors = errors
  end

  def as_json(options = {})
    hsh = {}
    errors_hash = @errors.is_a?(Hash) ? @errors : @errors.messages
    errors_hash.each do |field, errors|
      errors_as_hash = {}

      errors.each do |failure, context|
        errors_as_hash[failure.to_s.upcase] = context
      end

      hsh[field] = errors_as_hash
    end

    hsh
  end
end