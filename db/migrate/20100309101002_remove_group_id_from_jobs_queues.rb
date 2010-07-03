class RemoveGroupIdFromJobsQueues < ActiveRecord::Migration
  def self.up
    remove_column :jobs_queues, :group_id
  end

  def self.down
    add_column :jobs_queues, :group_id, :integer
  end
end
