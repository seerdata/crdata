class AddStatusToGroupUsers < ActiveRecord::Migration
  def self.up
    add_column :group_users, :status, :string
  end

  def self.down
    remove_column :group_users, :status
  end
end
