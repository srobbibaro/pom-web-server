class RemoveRangeFromLocationCheck < ActiveRecord::Migration
  def change
    remove_column :location_checks, :range
  end
end
