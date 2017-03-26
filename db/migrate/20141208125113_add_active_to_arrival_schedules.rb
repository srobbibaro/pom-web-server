class AddActiveToArrivalSchedules < ActiveRecord::Migration
  def change
    add_column :arrival_schedules, :active, :boolean
  end
end
