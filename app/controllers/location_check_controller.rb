class LocationCheckController < ApplicationController
  before_filter :authenticate_user!

  def location_checks
    render json: checks_for_user(current_user)
  end

  def find_location
    location = Geokit::Geocoders::IpGeocoder.geocode(request.remote_ip)
    render json: {longitude: location.longitude, latitude: location.latitude}
  end

  private

  def location_map(location)
     arrivals = ArrivalSchedule.where(id: location.location_check_matches.map(&:arrival_schedule_id))

    {
      id:        location.id,
      longitude: location.longitude,
      latitude:  location.latitude,
      date:      location.created_at.to_time,
      matches:   arrivals.map { |a| a.name }.join(','),
      test:      location.test ? 'yes' : 'no',
    }
  end

  def checks_for_user(user)
    locations = LocationCheck.where(user_id: user.id).order('updated_at DESC').limit(params[:limit])
    locations.map { |location|
      location_map location
    }
  end
end
