
Ahoy.geocode = false
class Ahoy::Store < Ahoy::DatabaseStore
 def track_visit(data)
#byebug
    data[:country] = request.headers["<country-header>"]
    data[:region] = request.headers["<region-header>"]
    data[:city] = request.headers["<city-header>"]
    super(data)
  end
end

# set to true for JavaScript tracking
#Ahoy.api = false

# set to true for geocoding
# we recommend configuring local geocoding first
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
#Ahoy.job_queue = :low_priority
