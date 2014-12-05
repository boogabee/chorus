class SetDefaultValueForJobNotifies < ActiveRecord::Migration
  def up
    execute("UPDATE jobs SET notifies = false")
  end

  def down
  end
end
