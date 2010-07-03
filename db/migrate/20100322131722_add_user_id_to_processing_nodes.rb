class AddUserIdToProcessingNodes < ActiveRecord::Migration
  def self.up
    add_column :processing_nodes, :user_id, :integer
  end

  def self.down
    remove_column :processing_nodes, :user_id
  end
end
