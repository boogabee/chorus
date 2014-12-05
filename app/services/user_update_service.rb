class UserUpdateService

  def initialize(params)
    @actor = params[:actor]
    @target = params[:target]
  end

  def update!(params)
    @target.attributes = params
    User.transaction do
      handle_admin_assignable_params(params) if @actor.admin?
      @target.save!
    end
  end

  private

  def handle_admin_assignable_params(opts)
    @target.admin = opts[:admin] if opts.key?(:admin)
    @target.developer = opts[:developer] if opts.key?(:developer)
    transfer_job_ownership if @target.admin_changed? && !@target.admin?
  end

  def transfer_job_ownership
    @target.owned_jobs.each do |job|
      job.reset_ownership! unless job.workspace.members.include? @target
    end
  end

end
