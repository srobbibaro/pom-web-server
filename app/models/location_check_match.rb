class LocationCheckMatch < ActiveRecord::Base
  belongs_to :arrival_schedule
  belongs_to :location_check
end
