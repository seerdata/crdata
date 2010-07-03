class AddShowMembersToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :show_members, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :groups, :show_members
  end
end
