class CreateDataSets < ActiveRecord::Migration
  def self.up
    create_table :data_sets do |t|
      t.text :data_location
      t.string :name
      t.text :description

      t.timestamps
    end
    
    # For data sets we need two longs....
    execute "ALTER TABLE data_sets ADD COLUMN data_size bigint"
    execute "ALTER TABLE data_sets ADD COLUMN num_records bigint"

    # Required index
    execute "CREATE UNIQUE INDEX data_sets_lower_name_idx ON data_sets(lower(name))" 
  end

  def self.down
    drop_table :data_sets
  end
end
