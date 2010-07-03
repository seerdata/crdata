class AddAwsKeyIdToProcessingNodes < ActiveRecord::Migration
  def self.up
    add_column :processing_nodes, :aws_key_id, :integer
  end

  def self.down
    remove_column :processing_nodes, :aws_key_id
  end
end
