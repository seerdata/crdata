class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.integer :logable_id
      t.string  :logable_type, :description

      t.timestamps
    end
    
    add_index :logs, :logable_id
    add_index :logs, :logable_type
  end

  def self.down
    drop_table :logs
  end
end
