class AddNameToAwsKeys < ActiveRecord::Migration
  def self.up
    add_column :aws_keys, :name, :string
  end

  def self.down
    remove_column :aws_keys, :name
  end
end
