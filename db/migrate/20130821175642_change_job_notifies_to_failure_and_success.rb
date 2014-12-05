class ChangeJobNotifiesToFailureAndSuccess < ActiveRecord::Migration
  def up
    add_column :jobs, :success_notify, :string, default: 'nobody'
    add_column :jobs, :failure_notify, :string, default: 'nobody'
    remove_column :jobs, :notifies
  end

  def down
    remove_column :jobs, :success_notify
    remove_column :jobs, :failure_notify
    add_column :jobs, :notifies, :boolean, default: true
  end
end
