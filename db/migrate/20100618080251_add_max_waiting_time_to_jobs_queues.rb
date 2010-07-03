class AddMaxWaitingTimeToJobsQueues < ActiveRecord::Migration
  def self.up
    add_column :jobs_queues, :max_waiting_time, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :jobs_queues, :max_waiting_time
  end
end
