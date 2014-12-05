class OracleSqlResultPresenter < SqlResultPresenter
  def to_hash
    hash = super

    reformat_values(hash, "date") do |value|
      DateTime.parse(value).strftime("%-m/%d/%Y")
    end
    reformat_values(hash, "timestamp") do |value|
      DateTime.parse(value).strftime("%-m/%d/%Y%l:%M:%S.%3N %p")
    end

    hash
  end

  private

  def reformat_values(hash, type, &block)
    index = 0
    columns = hash[:columns].reduce([]) do |indexes, column|
      if column[:data_type] == type
        indexes << index
      end

      index = index + 1
      indexes
    end

    hash[:rows].map do |row|
      columns.each do |i|
        row[i] = block.call(row[i])
      end
    end
  end
end