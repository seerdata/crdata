class SetAllTagsToLowerCase < ActiveRecord::Migration
  def self.up
    execute 'UPDATE tags SET name = LOWER(name);'
  end

  def self.down
  end
end
