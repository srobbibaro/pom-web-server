class ArrivalScheduleController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def locations
    render json: arrivals_for_user(current_user)
  end

  def schedule
    valid_recipients = ArrivalRecipient.valid_recipients(arrival_recipient_params)
    unless ArrivalSchedule.valid?(arrival_schedule_params) && valid_recipients.length > 0
      render json: {result: false, message: t('scheduled_arrival.error.invalid_params')}
      return
    end

    # Build/Update and save arrival schedule record
    s = ArrivalSchedule.where(user_id: current_user.id).where(id: arrival_schedule_params[:id]).first unless arrival_schedule_params[:id].nil?

    # Only allow one record with a particular name for each user
    saved_arrivals_with_name = s && s[:id] ?
      ArrivalSchedule.where(user_id: current_user.id).where(name: arrival_schedule_params[:name]).where.not(id: s[:id]) :
      ArrivalSchedule.where(user_id: current_user.id).where(name: arrival_schedule_params[:name])

    if saved_arrivals_with_name.count > 0
      render json: {result: false, message: t('scheduled_arrival.error.duplicate_name')}
      return
    end

    updated_params = arrival_schedule_params.merge({
      range:   ArrivalSchedule.valid_range!(arrival_schedule_params[:range].to_f),
      user_id: current_user.id,
    })

    if s
      s.update_attributes!(updated_params)
    else
      s = ArrivalSchedule.create(updated_params)
    end

    # Build/Update recipients for this scheduled arrival
    s.arrival_recipients = valid_recipients.map do |recipient|
      ArrivalRecipient.new(recipient)
    end

    render json: arrival_map(s).merge({result: true, message: t('scheduled_arrival.saved')})
  end

  def remove_schedule
    s = ArrivalSchedule.where(user_id: current_user.id).where(id: params[:id]).first
    if s
      s.destroy()
      render json: {
        result:  true,
        message: t('scheduled_arrival.removed')
      }
    else
      render json: {
        result: false
      }
    end
  end

  def check_location
    matching_arrivals = ArrivalSchedule.check_location_for_user(params, current_user, true)
    ret = ArrivalSchedule.determine_notifications(matching_arrivals)
    render json: ret, status: :ok
  end

  def process_locations
    matching_arrivals = ArrivalSchedule.process_locations_for_user(params, current_user, true)
    render json: matching_arrivals, status: :ok
  end

  private
  def valid_params
    params.require(:arrival_schedule).permit(
      :id, :name, :active, :longitude, :latitude, :range,
      recipients: [:notification_method, :mobile_carrier, :mobile_number, :email_address]
    )
  end

  def arrival_schedule_params
    @arrival_schedule_params ||= valid_params.tap{|h| h.delete(:recipients)}
  end

  def arrival_recipient_params
    @arrival_recipient_params ||= valid_params[:recipients]
  end

  def arrival_map(arrival)
    {
      id:                       arrival.id,
      name:                     arrival.name,
      longitude:                arrival.longitude,
      latitude:                 arrival.latitude,
      active:                   arrival.active ? "1" : "0",
      range:                    arrival.range,
      recipients:               arrival.arrival_recipients,
    }
  end

  def arrivals_for_user(user)
    ArrivalSchedule.where(user_id: user.id).order(updated_at: :desc).map { |a|
      arrival_map a
    }
  end
end
