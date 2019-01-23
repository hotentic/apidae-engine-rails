class AddBookingDataToApidaeObjs < ActiveRecord::Migration[5.2]
  def change
    add_column :apidae_objs, :booking_data, :jsonb
    Apidae::Obj.all.each do |o|
      val = o.read_attribute(:reservation)
      unless val.blank?
        if val.start_with?('[')
          o.update(booking_data: {'booking_entities' => val.gsub(/:(?<v>\w+)=>/, '"\k<v>":')})
        else
          o.update(booking_data: {'booking_desc' => {'fr' => val}})
        end
      end
    end
    remove_column :apidae_objs, :reservation
  end
end
