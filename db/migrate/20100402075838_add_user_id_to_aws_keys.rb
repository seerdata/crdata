class AddUserIdToAwsKeys < ActiveRecord::Migration
  def self.up
    add_column :aws_keys, :user_id, :integer
  end

  def self.down
    remove_column :aws_keys, :user_id
  end
end
