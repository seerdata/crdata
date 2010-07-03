class RemoveUrlAndAddBucketAndFileNameToDataSets < ActiveRecord::Migration
  def self.up
    remove_column :data_sets, :url
    add_column    :data_sets, :bucket, :string
    add_column    :data_sets, :file_name, :string
  end

  def self.down
    add_column    :data_sets, :url, :string
    remove_column :data_sets, :bucket
    remove_column :data_sets, :file_name 
  end
end
