class AddUserIdToJobs < ActiveRecord::Migration
  def self.up
    add_column    :jobs, :user_id, :integer
  end

  def self.down
    remove_column :jobs, :user_id 
  end
end
