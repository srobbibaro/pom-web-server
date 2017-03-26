class ArrivalRecipient < ActiveRecord::Base
  belongs_to :arrival_schedule

  def determine_notification_email
    self.notification_method == "text" ?
      SMSFu.sms_address(self.mobile_number, self.mobile_carrier) :
      self.email_address
  end

  def formatted_notification_method
    self.notification_method == "text" ?
      formatted_phone_number(self.mobile_number) :
      self.email_address
  end

  def self.valid_recipients(recipients)
    recipients.select { |r| valid?(r) }
  end

  def self.valid?(recipient)
    !recipient[:notification_method].blank? && (valid_email?(recipient) || valid_mobile?(recipient))
  end

  private
  def self.valid_email?(recipient)
    recipient[:notification_method] == 'email' && !recipient[:email_address].blank?
  end

  def formatted_phone_number(number)
    "(#{number[0..2]}) #{number[3..5]}-#{number.last(4)}"
  end

  def self.valid_mobile?(recipient)
    recipient[:notification_method] == 'text' &&
    !recipient[:mobile_carrier].blank? &&
    recipient[:mobile_carrier] != 'Select a Carrier' &&
    !recipient[:mobile_number].blank? &&
    !recipient[:mobile_number].match(/\A\d{10}\Z/).nil? &&
    !(SMSFu.sms_address(recipient[:mobile_number], recipient[:mobile_carrier]) rescue nil).nil?
  end
end
