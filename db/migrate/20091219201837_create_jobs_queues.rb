class CreateJobsQueues < ActiveRecord::Migration
  def self.up
    create_table :jobs_queues do |t|
      t.string :name

      t.timestamps
    end

    # Index...
    execute "CREATE UNIQUE INDEX jobs_queues_lower_name_idx ON jobs_queues (lower(name))" 

  end

  def self.down
    drop_table :jobs_queues
  end
end
