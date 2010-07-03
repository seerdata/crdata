class AddUuidToProcessingNodes < ActiveRecord::Migration
  def self.up
    add_column :processing_nodes, :uuid, :string
  end

  def self.down
    remove_column :processing_nodes, :uuid
  end
end
