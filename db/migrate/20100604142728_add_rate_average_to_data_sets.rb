class AddRateAverageToDataSets < ActiveRecord::Migration
  def self.up
    add_column :data_sets, :rate_average, :decimal, :default => 0, :precision => 6, :scale => 2
  end

  def self.down
    remove_column :data_sets, :rate_average
  end
end
