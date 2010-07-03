class AddColumnsToJobsQueues < ActiveRecord::Migration
  def self.up
    add_column :jobs_queues, :min_processing_nodes, :integer, :null => false, :default => 0
    add_column :jobs_queues, :max_processing_nodes, :integer, :null => false, :default => 0
    add_column :jobs_queues, :nr_jobs, :integer, :null => false, :default => 0
    add_column :jobs_queues, :max_idle_time, :integer, :null => false, :default => 0
    add_column :jobs_queues, :is_autoscalable, :boolean, :null => false, :default => false
    add_column :jobs_queues, :aws_key_id, :integer
  end

  def self.down
    remove_column :jobs_queues, :min_processing_nodes
    remove_column :jobs_queues, :max_processing_nodes
    remove_column :jobs_queues, :nr_jobs
    remove_column :jobs_queues, :max_idle_time
    remove_column :jobs_queues, :is_autoscalable
    remove_column :jobs_queues, :aws_key_id
  end
end
