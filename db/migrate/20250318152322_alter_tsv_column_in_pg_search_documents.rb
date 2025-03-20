class AlterTsvColumnInPgSearchDocuments < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      ALTER TABLE pg_search_documents DROP COLUMN IF EXISTS tsv_content;
      ADD COLUMN tsv_content tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('fr', coalesce(split_part(coalesce(content, ''), '§§§', 1), '')), 'A')    ||
        setweight(to_tsvector('fr', coalesce(split_part(coalesce(content, ''), '§§§', 2), '')), 'B')    ||
        setweight(to_tsvector('fr', coalesce(split_part(coalesce(content, ''), '§§§', 3), '')), 'C')    ||
        setweight(to_tsvector('fr', coalesce(split_part(coalesce(content, ''), '§§§', 4), '')), 'D')    ||
      ) STORED;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE pg_search_documents DROP COLUMN IF EXISTS tsv_content;
      ALTER TABLE pg_search_documents
            ADD COLUMN tsv_content tsvector GENERATED ALWAYS AS (
              to_tsvector('fr', coalesce(content, ''))
            ) STORED;
    SQL
  end
end
