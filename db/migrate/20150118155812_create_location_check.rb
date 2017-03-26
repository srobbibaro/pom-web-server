class CreateLocationCheck < ActiveRecord::Migration
  def change
    create_table :location_checks do |t|
      t.float :longitude
      t.float :latitude
      t.float :range
      t.integer :matches

      t.timestamps
    end

    add_reference :location_checks, :user, index: true
  end
end
