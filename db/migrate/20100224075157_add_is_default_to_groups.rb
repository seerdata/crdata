class AddIsDefaultToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :is_default, :boolean, :default => false, :null => false
  end

  def self.downo
    remove_column :groups, :is_default
  end
end
