class LocationMailer < ActionMailer::Base
  default from: ENV['DEFAULT_FROM_EMAIL_ADDRESS']

  def scheduled_arrival(user, notification)
    if notification[:email_addresses].length > 0
      user_display_name = user.display_name
      user_display_name = user.email if user_display_name.blank?
      mail(
        to:      notification[:email_addresses],
        from:    user.email,
        subject: 'Arrival',
        body:    "#{user_display_name} has arrived at the following location: #{notification[:arrival_name]}"
      )
    end
  end
end
