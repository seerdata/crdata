class AddColumnsToParameters < ActiveRecord::Migration
  def self.up
    add_column :parameters, :min_value, :integer
    add_column :parameters, :max_value, :integer
    add_column :parameters, :increment_value, :integer
  end

  def self.down
    remove_column :parameters, :min_value
    remove_column :parameters, :max_value
    remove_column :parameters, :increment_value
  end
end
