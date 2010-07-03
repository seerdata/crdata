class AddAllowLoginFieldToUsers < ActiveRecord::Migration
  def self.up
    add_column(:users, :allow_login, :boolean, :default => true, :null => false)
  end

  def self.down
    remove_column(:users, :allow_login)
  end
end
