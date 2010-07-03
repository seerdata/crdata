class AddNumberOfDatasetsToRScripts < ActiveRecord::Migration
  def self.up
    add_column :r_scripts, :number_of_datasets, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :r_scripts, :number_of_datasets
  end
end
