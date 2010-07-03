class CreateParameters < ActiveRecord::Migration
  def self.up
    create_table :parameters do |t|
      t.string  :name, :title, :kind, :default_value, :values 
      t.timestamps
      t.references :r_script
    end
    
    add_index :parameters, :r_script_id
  end

  def self.down
    drop_table :parameters
  end
end
