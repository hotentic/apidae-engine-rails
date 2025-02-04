class AddTsvColumnToPgSearchDocuments < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      CREATE TEXT SEARCH CONFIGURATION fr ( COPY = french );
      ALTER TEXT SEARCH CONFIGURATION fr
        ALTER MAPPING FOR hword, hword_part, word
        WITH unaccent, french_stem;

      ALTER TABLE pg_search_documents
      ADD COLUMN tsv_content tsvector GENERATED ALWAYS AS (
        to_tsvector('fr', coalesce(content, ''))
      ) STORED;
    SQL
  end

  def down
    execute <<-SQL
      DROP TEXT SEARCH CONFIGURATION IF EXISTS fr;
      ALTER TABLE pg_search_documents DROP COLUMN IF EXISTS tsv_content;
    SQL
  end
end
