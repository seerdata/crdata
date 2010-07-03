class CreateJobParameters < ActiveRecord::Migration
  def self.up
    create_table :job_parameters do |t|
      t.string :value
      t.references :job, :parameter
    end
    
    add_index :job_parameters, :job_id
    add_index :job_parameters, :parameter_id
  end

  def self.down
    drop_table :job_parameters
  end
end
