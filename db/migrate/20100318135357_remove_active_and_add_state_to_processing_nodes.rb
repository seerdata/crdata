class RemoveActiveAndAddStateToProcessingNodes < ActiveRecord::Migration
  def self.up
    remove_column :processing_nodes, :active
    add_column    :processing_nodes, :status, :string
  end

  def self.down
    add_column    :processing_nodes, :active, :boolean, :null => false, :default => false
    remove_column :processing_nodes, :status
  end
end
