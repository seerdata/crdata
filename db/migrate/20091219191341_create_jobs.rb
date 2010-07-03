class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.integer :r_script_id
      t.integer :jobs_queue_id
      t.integer :processing_node_id
      t.timestamp :submitted_at
      t.timestamp :started_at
      t.timestamp :completed_at
      t.boolean :successful
      t.string :status

      t.timestamps
    end

    # Needed indexes...
    add_index :jobs, :r_script_id
    add_index :jobs, :jobs_queue_id
    add_index :jobs, :submitted_at
    add_index :jobs, :started_at
    add_index :jobs, :completed_at
    add_index :jobs, :processing_node_id

  end

  def self.down
    drop_table :jobs
  end
end
