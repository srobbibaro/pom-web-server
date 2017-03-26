class CreateArrivalRecipient < ActiveRecord::Migration
  def change
    create_table :arrival_recipients do |t|
      t.belongs_to :arrival_schedule
      t.string :email_address
      t.integer :arrival_schedule_id
      t.timestamps
    end
  end
end
