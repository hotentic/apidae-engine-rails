class AddGinIndexToPgSearchDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :pg_search_documents, :tsv_content, using: :gin, algorithm: :concurrently
  end
end
