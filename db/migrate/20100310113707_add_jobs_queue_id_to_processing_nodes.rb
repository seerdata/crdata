class AddJobsQueueIdToProcessingNodes < ActiveRecord::Migration
  def self.up
    add_column :processing_nodes, :jobs_queue_id, :integer
  end

  def self.down
    remove_column :processing_nodes, :jobs_queue_id
  end
end
