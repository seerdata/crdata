class CreateAwsKeys < ActiveRecord::Migration
  def self.up
    create_table :aws_keys do |t|
      t.string     :access_key_id, :secret_access_key
      t.references :group

      t.timestamps
    end
  end

  def self.down
    drop_table :aws_keys
  end
end
