class RemoveDescriptionAndAddUserIdJobIdAndActionIdToLogs < ActiveRecord::Migration
  def self.up
    remove_column :logs, :description
    add_column    :logs, :user_id, :integer
    add_column    :logs, :job_id, :integer
    add_column    :logs, :action_id, :integer
  end

  def self.down
  end
end
