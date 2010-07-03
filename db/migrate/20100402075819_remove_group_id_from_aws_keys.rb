class RemoveGroupIdFromAwsKeys < ActiveRecord::Migration
  def self.up
    remove_column :aws_keys, :group_id
  end

  def self.down
    add_column :aws_keys, :group_id, :integer
  end
end
