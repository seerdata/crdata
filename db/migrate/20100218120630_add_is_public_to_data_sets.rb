class AddIsPublicToDataSets < ActiveRecord::Migration
  def self.up
    add_column :data_sets, :is_public, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :data_sets, :is_public
  end
end
