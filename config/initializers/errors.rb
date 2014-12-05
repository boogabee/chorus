class ApiValidationError < RuntimeError
  attr_reader :errors
  delegate :add, :to => :errors

  def initialize(*args)
    if args[0].instance_of? ChorusApiValidationFormat::UnlocalizedErrors
      @errors = args[0]
    else
      @errors = ChorusApiValidationFormat::UnlocalizedErrors.new(nil)
      add(*args) if args.any?
    end
  end

  def record
    self
  end
end
