class CreateLocationCheckMatchesTable < ActiveRecord::Migration
  def change
    create_table :location_check_matches do |t|
      t.belongs_to :location_check, index: true
      t.belongs_to :arrival_schedule, index: true
      t.timestamps
    end
  end
end
