RSpec::Matchers.define :have_error_on do |attribute|
  chain :with_message do |message_key|
    @message_key = message_key
  end

  chain :with_options do |options|
    @options = options
  end

  match do |model|
    model.valid? if model.errors.messages.empty?
    result = model.errors.messages.any?
    result &&= errors_on_attribute(model, attribute).any?
    result &&= errors_on_attribute_with_key(model, attribute, message_key).any? if message_key
    result &&= errors_on_attribute_with_key_and_options(model, attribute, message_key, options).any? if message_key && options

    result
  end

  def message_key
    @message_key
  end

  def options
    @options
  end

  def errors_on_attribute(model, attribute)
    model.errors.messages[attribute] || []
  end

  def errors_on_attribute_with_key(model, attribute, message_key)
    errors_on_attribute(model, attribute).select { |error| error[0] == message_key }
  end

  def errors_on_attribute_with_key_and_options(model, attribute, message_key, options)
    errors_on_attribute_with_key(model, attribute, message_key).select { |_, options_hash| options_hash == options }
  end

  failure_message_for_should do |model|
    if errors_on_attribute(model, attribute).nil? || errors_on_attribute(model, attribute).empty?
      "model had no errors on #{attribute}, actual errors were #{model.errors.messages.inspect}"
    elsif errors_on_attribute_with_key(model, attribute, message_key).empty?
      "model had no errors on #{attribute} with #{message_key.inspect}, actual errors on #{attribute} were #{model.errors_on(attribute).inspect}"
    elsif errors_on_attribute_with_key_and_options(model, attribute, message_key, options).empty?
      "model had no errors on #{attribute} with #{message_key.inspect} and #{options.inspect}, actual errors on #{attribute} were #{errors_on_attribute_with_key(model, attribute, message_key).inspect}"
    end
  end

  failure_message_for_should_not do |model|
    "model should not have error #{@message_key.inspect} on attribute #{attribute}, with options #{@options.inspect}, but did"
  end
end