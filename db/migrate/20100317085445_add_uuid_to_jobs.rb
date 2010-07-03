class AddUuidToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :uuid, :string
  end

  def self.down
    remove_column :jobs, :uuid
  end
end
