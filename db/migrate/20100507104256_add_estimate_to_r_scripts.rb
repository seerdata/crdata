class AddEstimateToRScripts < ActiveRecord::Migration
  def self.up
    add_column :r_scripts, :estimate, :string
  end

  def self.down
    remove_column :r_scripts, :estimate
  end
end
