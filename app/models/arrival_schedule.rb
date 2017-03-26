class ArrivalSchedule < ActiveRecord::Base
  has_many :arrival_recipients, :dependent => :destroy
  has_many :location_check_matches
  has_many :location_trackings, :dependent => :destroy
  acts_as_mappable :default_units => :kms,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  MIN_RANGE = 50.0
  MAX_RANGE = 1000.0

  def self.check_location_for_user(params, user, test=false)
    latitude  = params[:latitude].try(:to_f)
    longitude = params[:longitude].try(:to_f)

    return [] unless user && latitude && longitude

    arrivals = active_locations_for_user(user).select { |arrival|
      !recent_arrival?(arrival) &&
      arrival.distance_to([latitude, longitude]) < determine_range(arrival.range)
    }

    check_record = add_location_check_record(longitude, latitude, user, test)

    arrivals.each { |arrival|
      LocationCheckMatch.create(location_check: check_record, arrival_schedule: arrival)
    }
  end

  def self.process_locations_for_user(params, user, test=false)
    latitude  = params[:latitude].try(:to_f)
    longitude = params[:longitude].try(:to_f)

    if user && latitude && longitude
      add_location_check_record(longitude, latitude, user, test)
    end

    []
  end

  def self.active_locations_for_user(user)
    ArrivalSchedule.where(user_id: user.id).where(active: true)
  end

  def self.recent_arrival?(arrival)
    # For now, we are allowing a location to be notified an unlimited number of
    # times. However, we still want to throttle this request to prevent a
    # recipient from being spammed.
    arrival.location_check_matches.where("created_at >= ?", Time.zone.now - (2 * 60)).count > 0
  end

  def self.valid?(arrival_schedule)
    numeric?(arrival_schedule[:latitude]) &&
    numeric?(arrival_schedule[:longitude]) &&
    !arrival_schedule[:name].blank?
  end

  def self.valid_range!(range)
    range = MIN_RANGE if range < MIN_RANGE
    range = MAX_RANGE if range > MAX_RANGE
    range
  end

  def self.determine_notifications(arrivals)
    arrivals.map { |m|
      email_addresses = m.arrival_recipients.map { |r|
        r.determine_notification_email
      }
      if email_addresses.length > 0
        {
          email_addresses: email_addresses,
          method:          m.arrival_recipients.map { |r| r.formatted_notification_method }.join(', '),
          arrival_name:    m.name,
          arrival_id:      m.id,
          notification:    build_arrival_notification(m.name, m.arrival_recipients)
        }
      end
    }.compact
  end

  private
  def self.build_arrival_notification(location_name, recipients)
    recipients = recipients.map { |r| r.formatted_notification_method }
    short = "Arrival: #{location_name}"
    long  = "#{recipients.to_sentence} " +
            "#{recipients.length < 2 ? 'has' : 'have'} been notified."
    {
      short: short,
      long:  long,
      full:  "#{short}\n\n#{long}"
    }
  end

  def self.determine_range(range)
    # Add 5m to ensure that any "close" values from caller are included and
    # convert to km from m.
    (range + 5.0) / 1000.0
  end

  def self.add_location_check_record(longitude, latitude, user, test=false)
    LocationCheck.create(longitude: longitude, latitude: latitude, user_id: user.id, test: test)
  end

  def self.numeric?(val)
    Float(val) != nil rescue false
  end
end
