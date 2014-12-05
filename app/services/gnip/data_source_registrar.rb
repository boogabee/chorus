module Gnip
  class DataSourceRegistrar

    def self.create!(data_source_attributes, owner)
      chorus_gnip = ChorusGnip.new({:url => data_source_attributes[:stream_url],
                                    :username => data_source_attributes[:username],
                                    :password => data_source_attributes[:password]
                                   })
      if chorus_gnip.auth
        data_source = GnipDataSource.new(data_source_attributes)
        data_source.owner = owner
        data_source.save!
        Events::GnipDataSourceCreated.by(owner).add(:gnip_data_source => data_source)
        data_source
      else
        raise ApiValidationError.new(:connection, :generic, {:message => "Url, username and password combination is Invalid"})
      end
    end

    def self.update!(data_source_id, data_source_attributes)
      data_source = GnipDataSource.find(data_source_id)

      if data_source_attributes[:password].blank?
        data_source_attributes[:password] = data_source.password
      end

      data_source_attributes.delete(:owner)

      chorus_gnip = ChorusGnip.new({:url => data_source_attributes[:stream_url],
                                    :username => data_source_attributes[:username],
                                    :password => data_source_attributes[:password]
                                   })

      if chorus_gnip.auth
        data_source.attributes = data_source_attributes
        data_source.save!
        data_source
      else
        raise ApiValidationError.new(:connection, :generic, {:message => "Url, username and password combination is Invalid"})
      end
    end
  end
end