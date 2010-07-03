class CreateAccesses < ActiveRecord::Migration
  def self.up
    create_table :accesses do |t|
      t.references :group
      t.references :accessable, :polymorphic => true
      t.timestamps
    end
  end

  def self.down
    drop_table :accesses
  end
end
