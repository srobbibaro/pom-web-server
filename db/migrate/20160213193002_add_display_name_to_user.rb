class AddDisplayNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :display_name, :string, default: nil
  end
end
