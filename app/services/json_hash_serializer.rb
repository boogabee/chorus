class JsonHashSerializer
  def self.dump(hash)
    JSON.dump(hash)
  end

  def self.load(value)
    result = JSON.load(value)
    result.present? ? result : {}
  end
end