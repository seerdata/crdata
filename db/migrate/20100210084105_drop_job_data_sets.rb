class DropJobDataSets < ActiveRecord::Migration
  def self.up
    drop_table :job_data_sets
  end

  def self.down
    create_table :job_data_sets do |t|
      t.integer :job_id
      t.integer :data_set_id

      t.timestamps
    end

    # Index
    add_index :job_data_sets, :job_id
    add_index :job_data_sets, :data_set_id
  end
end
