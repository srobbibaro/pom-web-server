class CreateArrivalSchedules < ActiveRecord::Migration
  def change
    create_table(:arrival_schedules) do |t|
      t.float :longitude
      t.float :latitude

      t.timestamps
    end

    add_reference :arrival_schedules, :user, index: true
  end
end
