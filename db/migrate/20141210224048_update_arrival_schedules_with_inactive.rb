class UpdateArrivalSchedulesWithInactive < ActiveRecord::Migration
  def change
    ArrivalSchedule.all.each { |arrival|
      if arrival[:active].nil?
        arrival[:active] = false
        arrival.save!
      end
    }
  end
end
