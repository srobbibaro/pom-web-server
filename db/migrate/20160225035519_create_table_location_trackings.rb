class CreateTableLocationTrackings < ActiveRecord::Migration
  def change
    create_table :location_trackings do |t|
      t.integer :state
      t.belongs_to :arrival_schedule, index: true
      t.timestamps
    end
  end
end
