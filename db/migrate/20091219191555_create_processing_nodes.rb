class CreateProcessingNodes < ActiveRecord::Migration
  def self.up
    create_table :processing_nodes do |t|
      t.string  :ip_address
      t.string  :node_identifier  # In EC2 this is the instance-id, but for generality anything is allowed
      t.boolean :active

      t.timestamps
    end
  end

  def self.down
    drop_table :processing_nodes
  end
end
