class BoxplotSummary
  def self.summarize(ntiles_for_each_bucket, number_of_buckets)
    boxplot_entries = []

    all_buckets = ntiles_for_each_bucket.map{|r| r[:bucket]}.uniq
    total = ntiles_for_each_bucket.inject(0) { |sum, r| sum + r[:count] }

    all_buckets.each do |bucket|
      quartiles_for_bucket = ntiles_for_each_bucket.select{ |r| r[:bucket] == bucket }
      overall_min = quartiles_for_bucket.first[:min]
      overall_max = quartiles_for_bucket.last[:max]
      total_in_bucket = quartiles_for_bucket.inject(0) { |sum, r| sum + r[:count] }
      percentage = "%0.2f\%" % (total_in_bucket.to_f / total * 100)

      boxplot_entries << {
          :bucket => bucket,
          :count => total_in_bucket,
          :min => overall_min,
          :max => overall_max,
          :percentage => percentage
      }.merge(quartiles(quartiles_for_bucket))
    end

    return sort_entries(number_of_buckets, boxplot_entries)
  end

  private

  def self.mean(a,b)
    (a + b) / 2.0
  end

  def self.sort_entries(number_of_buckets, boxplot_entry)
    boxplot_entry = boxplot_entry.sort { |a, b| b[:percentage] <=> a[:percentage] }
    boxplot_entry = boxplot_entry.take(number_of_buckets) if number_of_buckets.present?
    return boxplot_entry
  end

  def self.quartiles(quartiles_for_bucket)
    # This is necessary because sometimes SQL returns fewer than 4 quartiles
    case quartiles_for_bucket.length
      when 1
        median = first_quartile = third_quartile = quartiles_for_bucket[0][:min]
      when 2
        median = mean(quartiles_for_bucket[0][:max], quartiles_for_bucket[1][:min])
        first_quartile = mean(quartiles_for_bucket[0][:max], median)
        third_quartile = mean(quartiles_for_bucket[1][:min], median)
      when 3
        median = quartiles_for_bucket[1][:min]
        first_quartile = mean(quartiles_for_bucket[0][:max], quartiles_for_bucket[1][:min])
        third_quartile = mean(quartiles_for_bucket[1][:max], quartiles_for_bucket[2][:min])
      else
        median = mean(quartiles_for_bucket[1][:max], quartiles_for_bucket[2][:min])
        first_quartile = mean(quartiles_for_bucket[0][:max], quartiles_for_bucket[1][:min])
        third_quartile = mean(quartiles_for_bucket[2][:max], quartiles_for_bucket[3][:min])
    end

    return {:median => median,
            :first_quartile => first_quartile,
            :third_quartile => third_quartile}
  end
end
