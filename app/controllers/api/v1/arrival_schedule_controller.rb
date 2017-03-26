class Api::V1::ArrivalScheduleController < Api::ApiController
  def check_location
    ret = []
    if authenticated_user
      matching_arrivals = ArrivalSchedule.check_location_for_user(params, authenticated_user, false)
      ret = ArrivalSchedule.determine_notifications(matching_arrivals).map { |n|
        LocationMailer.scheduled_arrival(authenticated_user, n).deliver

        {
          method: n[:method],
          name:   n[:arrival_name],
          id:     n[:arrival_id],
          notification: n[:notification]
        }
      }
    end
    render json: ret, status: :ok
  end

  def process_locations
    matching_arrivals = ArrivalSchedule.process_locations_for_user(params, authenticated_user, false)
    render json: matching_arrivals, status: :ok
  end

  def active_locations
    ret = []
    if authenticated_user
      ret = ArrivalSchedule.active_locations_for_user(authenticated_user).map { |arrival|
        {
          id:        arrival.id,
          name:      arrival.name,
          longitude: arrival.longitude,
          latitude:  arrival.latitude,
          range:     arrival.range,
        }
      }
    end
    render json: ret, status: :ok
  end

end
