class CreateTsearchVectors < ActiveRecord::Migration
  def self.up
   DataSet.check_for_vector_column
   RScript.check_for_vector_column
  end

  def self.down
    execute('DROP INDEX r_scripts_fts_vectors_index;')
    execute('DROP INDEX data_sets_fts_vectors_index;')
    execute('ALTER TABLE r_scripts DROP COLUMN vectors;')
    execute('ALTER TABLE data_sets DROP COLUMN vectors;')
  end
end
