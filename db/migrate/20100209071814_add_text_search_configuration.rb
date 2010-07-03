class AddTextSearchConfiguration < ActiveRecord::Migration
  def self.up
    execute('CREATE TEXT SEARCH CONFIGURATION public.default ( COPY = pg_catalog.english );')
  end

  def self.down
    execute('DROP TEXT SEARCH CONFIGURATION public.default;')
  end
end
