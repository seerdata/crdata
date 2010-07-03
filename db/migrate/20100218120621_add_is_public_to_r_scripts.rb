class AddIsPublicToRScripts < ActiveRecord::Migration
  def self.up
    add_column :r_scripts, :is_public, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :r_scripts, :is_public
  end
end
