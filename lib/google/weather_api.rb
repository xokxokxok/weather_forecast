module Google
  class WeatherApi
    FORECAST_DAYS = 10

    attr_reader :client

    def initialize(client: nil)
      @client = client.presence || WeatherClient.new
    end

    def current_conditions(latitude:, longitude:, zip_code: nil)
      path = 'currentConditions:lookup'
      query = location_query(latitude, longitude)
      cache_key = build_cache_key('current_conditions', latitude, longitude, zip_code)

      client.get(path, query:, cache_key:)
    end

    def forecast_days(latitude:, longitude:, zip_code: nil)
      path = 'forecast/days:lookup'
      query = location_query(latitude, longitude).merge(days: FORECAST_DAYS, pageSize: FORECAST_DAYS)
      cache_key = build_cache_key('forecast_days', latitude, longitude, zip_code)

      client.get(path, query:, cache_key:)
    end

    private

    def location_query(latitude, longitude)
      {
        'location.latitude' => latitude,
        'location.longitude' => longitude
      }
    end

    def build_cache_key(type, latitude, longitude, zip_code)
      return "weather_#{type}_zip_#{zip_code}" if zip_code.present?

      "weather_#{type}_#{latitude}_#{longitude}"
    end
  end
end
