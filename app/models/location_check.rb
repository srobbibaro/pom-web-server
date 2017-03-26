class LocationCheck < ActiveRecord::Base
  has_many :location_check_matches
  acts_as_mappable :default_units => :kms,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude
end
