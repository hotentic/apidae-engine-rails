class AddTagsDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :tags_data, :jsonb
  end
end
