class AddRangeToArrivalSchedules < ActiveRecord::Migration
  def change
    add_column :arrival_schedules, :range, :float
    ArrivalSchedule.update_all(:range => 50.0)
  end
end
