module Jasmine
  class Server
    def start
      if Jasmine::Dependencies.legacy_rack?
        handler = Rack::Handler.get('webrick')
        handler.run(@application, :Port => @port, :AccessLog => [])
      else
        server = Rack::Server.new(:Port => @port, :AccessLog => [], :server => 'mizuno')
        # workaround for Rack bug, when Rack > 1.2.1 is released Rack::Server.start(:app => Jasmine.app(self)) will work
        server.instance_variable_set(:@app, @application)
        server.start
      end
    end
  end
end