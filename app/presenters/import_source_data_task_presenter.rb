class ImportSourceDataTaskPresenter < JobTaskPresenter
  def to_hash
    hsh = super

    hsh.merge!({
                    :source_id => model.payload.source_id,
                    :destination_id => model.payload.destination_id,
                    :row_limit => model.payload.row_limit,
                    :truncate => model.payload.truncate,
                    :source_name => model.payload.source.name,
                    :destination_name => model.payload.destination_name || model.payload.destination.name
                }) if model.valid_payload?

    hsh
  end
end
