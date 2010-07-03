class CreateRScripts < ActiveRecord::Migration
  def self.up
    create_table :r_scripts do |t|
      t.text :source_code
      t.integer :effort_level
      t.string :name
      t.text :description

      t.timestamps
    end

    # Indexes
    execute "CREATE UNIQUE INDEX r_scripts_lower_name_idx ON r_scripts (lower(name))"

  end

  def self.down
    drop_table :r_scripts
  end
end
