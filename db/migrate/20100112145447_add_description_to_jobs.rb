class AddDescriptionToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :description, :string
  end

  def self.down
    remove_column :jobs, :description
  end
end
