class AddNameToArrivalSchedules < ActiveRecord::Migration
  def change
    add_column :arrival_schedules, :name, :string

    i = 1
    ArrivalSchedule.all.each { |arrival|
      if arrival[:name].nil?
        i = i + 1
        arrival[:name] = "Not named (#{i})"
        arrival.save!
      end
    }
  end
end
