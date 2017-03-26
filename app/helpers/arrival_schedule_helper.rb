require 'sms_fu/sms_fu_helper'
module ArrivalScheduleHelper
  def carrier_select_tag
    extend SMSFuHelper
    carrier_select
  end
end
