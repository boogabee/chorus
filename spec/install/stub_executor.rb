class StubExecutor
  attr_reader :calls, :call_order

  def initialize
    @call_order = []
    @calls = {}
  end

  def method_missing(method_name, *args, &block)
    @call_order << method_name.to_sym
    @calls[method_name.to_sym] = args
  end
end