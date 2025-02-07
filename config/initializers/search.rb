Rails.configuration.to_prepare do
  require 'pg_search'

  PgSearch.multisearch_options = {
    using: {tsearch: {dictionary: 'fr'}},
    ignoring: :accents
  }

  PgSearch::Document.pg_search_scope(:tsv_search, lambda { |*args|
    {
      query: args.first,
      against: [:content],
      ignoring: :accents,
      using: {
        tsearch: {
          dictionary: 'fr',
          prefix: true,
          tsvector_column: ["tsv_content"]
        }
      }
    }
  })
end
