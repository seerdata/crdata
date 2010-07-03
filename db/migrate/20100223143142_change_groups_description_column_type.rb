class ChangeGroupsDescriptionColumnType < ActiveRecord::Migration
  def self.up
    change_column :groups, :description, :text
  end

  def self.down
    change_column :groups, :description, :string
  end
end
