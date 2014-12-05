module Properties
  def self.load_file(file_path)
    result = {}
    compacted_lines(file_path).each do |line|
      match = line.match(/\s*(?<key>[^=\s]*)\s*=\s*(?<value>.*)/)
      next unless match
      keys = match["key"].split(".")
      val = type_cast(match["value"].strip)

      parent = result
      keys.first(keys.length-1).each do |key|
        parent = parent[key] || parent[key] = {}
      end
      parent[keys.last] = val
    end
    result
  end

  def self.dump_file(hash, destination_file_path)
    list = self.property_list(hash)
    File.open(destination_file_path, 'w') do |f|
      list.each { |property| f.print(property, "\n") }
    end
  end

  private
  def self.property_list(hash, parents='')
    hash.map {|key, value|
      if value.is_a?(Hash)
        self.property_list(value, parents + "#{key}.")
      else
        ["#{parents}#{key}= #{value}"]
      end
    }.flatten
  end

  def self.compacted_lines(file_path)
    propertiesString = File.read(file_path)
    lineJoiningRegex = /\\\s*\n/
    joinedLines = propertiesString.gsub(lineJoiningRegex, '').split("\n")
    joinedLines.reject {|line| line.match(/^\s*#/) }
  end

  def self.type_cast(value)
    case value
      when 'true'
        true
      when 'false'
        false
      when /^\[.*\]$/
         value.gsub('[', '').gsub(']', '').split(',').map(&:strip)
      when /^-?\d+$/
        value.to_i
      when /^-?\d+\.?\d*$/
        value.to_f
      else
        value
    end
  end
end