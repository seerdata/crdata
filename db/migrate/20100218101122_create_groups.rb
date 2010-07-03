class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name, :description, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
