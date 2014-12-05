require 'ipaddr'

module Alpine
  class AlpineController < ApplicationController
    before_filter :check_work_flow_enabled, :enforce_localhost_only

    private

    def check_work_flow_enabled
      head :not_found unless License.instance.workflow_enabled?
    end

    def enforce_localhost_only
      head :not_found unless address_local?(request.remote_ip) && address_local?(request.remote_addr)
    end

    def address_local?(ip)
      local_addresses = ActionDispatch::Request::LOCALHOST + ['::ffff:127.0.0.1']
      local_addresses.any? {|local_addr_pattern| local_addr_pattern === ip }
    end
  end
end
