require 'net/http'
require 'uri'

module Alpine
  class API
    class RunError < StandardError; end

    def self.delete_work_flow(work_flow)
      new.delete_work_flow(work_flow)
    end

    def self.create_work_flow(work_flow, body)
      new.create_work_flow(work_flow, body)
    end

    def self.run_work_flow_task(task)
      user = task.job.owner
      new(user: user).run_work_flow(task.payload, task: task)
    end

    def self.run_work_flow(work_flow, user)
      new(user: user).run_work_flow(work_flow)
    end

    def self.stop_work_flow(killer, user=killer.job.owner)
      new(user: user).stop_work_flow(killer.killable_id)
    end

    def self.copy_work_flow(work_flow, new_id)
      new.copy_work_flow(work_flow, new_id)
    end

    # INSTANCE METHODS

    def initialize(options = {})
      @config = options[:config] || ChorusConfig.instance
      @license = options[:license] || License.instance
      @user = options[:user] || User.current_user
    end

    def delete_work_flow(work_flow)
      if_enabled { request_deletion(work_flow) }
    end

    def create_work_flow(work_flow, body)
      if_enabled { request_creation(body, work_flow) }
    end

    def run_work_flow(work_flow, options = {})
      if_enabled do
        ensure_session
        request_run(work_flow, options)
      end
    end

    def stop_work_flow(process_id)
      if_enabled do
        ensure_session
        request_stop(process_id)
      end
    end

    def copy_work_flow(work_flow, new_id)
      if_enabled { request_copy(work_flow, new_id) }
    end

    private

    attr_reader :config, :license, :user

    def if_enabled
      yield if license.workflow_enabled?
    end

    def ensure_session
      unless Session.not_expired.where(user_id: user.id).present?
        session = Session.new
        session.user = user
        session.save!
      end
    end

    def request_creation(body, work_flow)
      request_base.post(create_path(work_flow), body, {'Content-Type' => 'application/xml'})
    end

    def request_deletion(work_flow)
      request_base.delete(delete_path(work_flow))
    rescue SocketError, Errno::ECONNREFUSED, TimeoutError => e
      log_error(e)
    end

    def request_stop(process_id)
      request_base.post(stop_path(process_id), '')
    rescue StandardError => e
      log_error(e)
    end

    def request_run(work_flow, options)
      response = request_base.post(run_path(work_flow, options), '')
      unless response.code == '200' && (process_id = JSON.parse(response.body)['process_id']).present?
        raise RunError.new(response.body)
      end
      process_id
    rescue StandardError => e
      log_error(e)
      raise e
    end

    def request_copy(work_flow, new_id)
      response = request_base.post(copy_path(work_flow, new_id), '')
      raise StandardError(response.body) unless response.code == '201'
    rescue Exception => e
      log_error(e)
      raise ModelNotCreated.new('Failed to copy workflow.')
    end

    def delete_path(work_flow)
      params = {
        :method => 'deleteWorkFlow',
        :session_id => session_id,
        :workfile_id => work_flow.id
      }
      path_with(params)
    end

    def create_path(work_flow)
      params = {
        :method => 'importWorkFlow',
        :session_id => session_id,
        :file_name => work_flow.file_name,
        :workfile_id => work_flow.id,
        :workspace_id => work_flow.workspace.id
      }
      path_with(params)
    end

    def run_path(work_flow, options)
      params = {
        method: 'runWorkFlow',
        session_id: session_id,
        workfile_id: work_flow.id
      }
      params[:job_task_id] = options[:task].id if options[:task]

      path_with(params)
    end

    def stop_path(process_id)
      params = {
        method: 'stopWorkFlow',
        session_id: session_id,
        process_id: process_id
      }
      path_with(params)
    end

    def copy_path(work_flow, new_id)
      params = {
        :method => 'duplicateWorkFlow',
        :session_id => session_id,
        :workfile_id => work_flow.id,
        :new_workfile_id => new_id
      }
      path_with(params)
    end

    def base_url
      URI(config.workflow_url)
    end

    def request_base
      Net::HTTP.new(base_url.host, base_url.port)
    end

    def session_id
      Session.not_expired.where(user_id: user.id).first.session_id
    end

    def path_with(params)
      "/alpinedatalabs/main/chorus.do?#{params.to_query}"
    end

    def log_error(e)
      pa "Unable to connect to an Alpine at #{base_url}. Encountered #{e.class}: #{e}"
    end
  end
end
