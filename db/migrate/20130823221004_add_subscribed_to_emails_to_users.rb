class AddSubscribedToEmailsToUsers < ActiveRecord::Migration
  def up
    add_column :users, :subscribed_to_emails, :boolean, :default => true
    execute("UPDATE users SET subscribed_to_emails = true")
  end

  def down
    remove_column :users, :subscribed_to_emails
  end
end
