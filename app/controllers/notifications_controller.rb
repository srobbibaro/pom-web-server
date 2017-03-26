class NotificationsController < ApplicationController
  before_filter :authenticate_user!, :check_admin!

  def index
    @notifications = LocationCheck.all.order('updated_at DESC').limit(30).map { |location|
      location_map location
    }
  end

  private
  def location_map(location)
    arrivals = ArrivalSchedule.where(id: location.location_check_matches.map(&:arrival_schedule_id))

    {
      id:        location.id,
      user:      User.find(location.user_id),
      longitude: location.longitude.round(6),
      latitude:  location.latitude.round(6),
      date:      location.created_at.to_time,
      matches:   arrivals.map { |a| a.name }.join(','),
      test:      location.test ? 'yes' : 'no',
    }
  end

  def check_admin!
    render text: "You are not authorized for this action!", status: :unauthorized unless current_user.admin?
  end

end
