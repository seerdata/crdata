class AddIsPublicToJobsQueues < ActiveRecord::Migration
  def self.up
    add_column :jobs_queues, :is_public, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :jobs_queues, :is_public
  end
end
