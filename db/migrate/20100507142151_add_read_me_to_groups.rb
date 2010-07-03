class AddReadMeToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :read_me, :text
  end

  def self.down
    remove_column :groups, :read_me
  end
end
