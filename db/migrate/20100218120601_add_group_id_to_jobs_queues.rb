class AddGroupIdToJobsQueues < ActiveRecord::Migration
  def self.up
    add_column :jobs_queues, :group_id, :integer
  end

  def self.down
    remove_column :jobs_queues, :group_id
  end
end
