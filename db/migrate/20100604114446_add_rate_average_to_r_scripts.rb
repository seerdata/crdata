class AddRateAverageToRScripts < ActiveRecord::Migration
  def self.up
    add_column :r_scripts, :rate_average, :decimal, :default => 0, :precision => 6, :scale => 2
  end

  def self.down
    remove_column :r_scripts, :rate_average
  end
end
