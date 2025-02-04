class AddColumnsToPgSearchDocuments < ActiveRecord::Migration[7.2]
  def up
    # extra attributes columns
    add_column :pg_search_documents, :searchable_fields, :jsonb
  end

  def down
    remove_column :pg_search_documents, :searchable_fields, if_exists: true
  end
end
