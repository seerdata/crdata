class RemoveColumnsFromDataSets < ActiveRecord::Migration
  def self.up
    remove_column :data_sets, :data_location
    remove_column :data_sets, :data_size
    remove_column :data_sets, :num_records
    remove_column :data_sets, :data_content_type
    remove_column :data_sets, :data_file_size
    remove_column :data_sets, :data_updated_at
    rename_column :data_sets, :data_file_name, :url
  end

  def self.down
    add_column :data_sets, :data_location, :text
    execute "ALTER TABLE data_sets ADD COLUMN data_size bigint"
    execute "ALTER TABLE data_sets ADD COLUMN num_records bigint"
    add_column :data_sets, :data_content_type, :string
    add_column :data_sets, :data_file_size, :integer
    add_column :data_sets, :data_updated_at, :datetime
    rename_column :data_sets, :url, :data_file_name
  end
end
