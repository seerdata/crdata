class ChangeUsersIsAdminToInteger < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE users ALTER COLUMN is_admin DROP DEFAULT;
             ALTER TABLE users ALTER COLUMN is_admin TYPE integer USING int4(is_admin);
             ALTER TABLE users ALTER COLUMN is_admin SET default 0;")

  end

  def self.down
    execute("ALTER TABLE users ALTER COLUMN is_admin DROP DEFAULT;
             ALTER TABLE users ALTER COLUMN is_admin TYPE boolean USING bool(is_admin);
             ALTER TABLE users ALTER COLUMN is_admin SET default false;")

  end
end
