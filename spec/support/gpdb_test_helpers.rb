module GpdbTestHelpers
  def stub_gpdb(account, query_values)
    any_instance_of(GreenplumConnection) do |data_source|
      query_values.each do |query, response|
        stub(data_source).prepare_and_execute_statement(query).times(any_times) {
          GreenplumSqlResult.new.tap do |result|
            result_set = clone_response(response)
            keys = result_set[0].keys
            keys.each do |key|
              value = result_set[0][key]
              result.add_column(key, value.is_a?(Integer) ? "integer" : "string")
            end
            result_set.each do |row|
              result.add_row(keys.map {|key| row[key]} )
            end
          end
        }
      end
    end
  end

  def stub_gpdb_fail
    any_instance_of(GreenplumConnection) do |data_source|
      stub(data_source).prepare_and_execute_statement.with_any_args { raise PostgresLikeConnection::QueryError }
    end
  end

  def clone_response(response)
    return response.call if response.respond_to?(:call)
    response.map(&:clone)
  end
end
