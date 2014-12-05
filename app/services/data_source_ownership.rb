module DataSourceOwnership
  class << self

    def change(updater, data_source, new_owner)
      if data_source.shared?
        change_owner_of_shared(data_source, new_owner)
      else
        change_owner_of_unshared(data_source, new_owner)
      end

      Events::DataSourceChangedOwner.by(updater).add(
        :data_source => data_source,
        :new_owner => new_owner
      )
    end

    private

    def change_owner_of_shared(data_source, new_owner)
      ActiveRecord::Base.transaction do
        owner_account = data_source.owner_account
        owner_account.owner = new_owner
        owner_account.save!
        data_source.owner = new_owner
        data_source.save!
      end
    end

    def change_owner_of_unshared(data_source, new_owner)
      ensure_user_has_account(data_source, new_owner)
      data_source.owner = new_owner
      data_source.save!
    end

    def ensure_user_has_account(data_source, new_owner)
      data_source.account_for_user!(new_owner)
    end

  end
end