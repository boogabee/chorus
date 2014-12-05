class ClearFileCacheStore < ActiveRecord::Migration
  def up
    cache_path = Rails.root + 'tmp/cache'
    cache_path.rmtree if cache_path.exist?
  end
end
