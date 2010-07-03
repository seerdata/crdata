class AddAwsKeyIdToDataSets < ActiveRecord::Migration
  def self.up
    add_column :data_sets, :aws_key_id, :integer
  end

  def self.down
    remove_column :data_sets, :aws_key_id
  end
end
