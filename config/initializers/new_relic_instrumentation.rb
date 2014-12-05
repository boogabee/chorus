if ENV["CHORUS_NEWRELIC_ENABLED"] == "true"
  require 'new_relic/agent/method_tracer'
  EventsController.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :index
  end
end
