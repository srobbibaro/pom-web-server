class UpdateLocationCheckColumns < ActiveRecord::Migration
  def up
    remove_column :location_checks, :matches
    add_column :location_checks, :test, :boolean
    LocationCheck.update_all(test: false)
  end

  def down
    remove_column :location_checks, :test
    add_column :location_checks, :matches, :string
  end
end
