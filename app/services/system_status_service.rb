class SystemStatusService

  def self.refresh
    new(Date.current, License.instance).refresh
  end

  def self.latest
    SystemStatus.last || refresh
  end

  def initialize(current_date, license)
    @current_date = current_date
    @license = license
  end

  def refresh
    ss = SystemStatus.create!({:expired => expired?, :user_count_exceeded => users_exceeded?}, :without_protection => true)
    notify_admins if should_notify?
    ss
  end

  def users_exceeded?
    @license.limit_user_count? && any_user_count_exceeded?
  end

  private

  def expired?
    @license.expired?(@current_date)
  end

  def any_user_count_exceeded?
    {
        :developers => :developer_count,
        :admins => :admin_count,
        :collaborators => :count
    }.any? { |key, count_method| @license[key] < User.send(count_method) }
  end

  def should_notify?
    @license.expired?(2.weeks.from_now.to_date)
  end

  def notify_admins
    User.admin.each { |admin| Mailer.chorus_expiring(admin, @license) }
  end
end
