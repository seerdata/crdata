class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.string :kind, :value
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end
