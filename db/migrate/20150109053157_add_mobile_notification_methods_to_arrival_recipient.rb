class AddMobileNotificationMethodsToArrivalRecipient < ActiveRecord::Migration
  def change
    add_column :arrival_recipients, :notification_method, :string
    add_column :arrival_recipients, :mobile_number, :string
    add_column :arrival_recipients, :mobile_carrier, :string
  end
end
