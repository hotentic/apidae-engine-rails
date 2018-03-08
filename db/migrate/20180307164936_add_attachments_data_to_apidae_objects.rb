class AddAttachmentsDataToApidaeObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :apidae_objects, :attachments_data, :jsonb
  end
end
