class AddDataSetIdToJobParameters < ActiveRecord::Migration
  def self.up
    add_column :job_parameters, :data_set_id, :integer
    add_index  :job_parameters, :data_set_id
  end

  def self.down
    remove_column :job_parameters, :data_set_id
  end
end
