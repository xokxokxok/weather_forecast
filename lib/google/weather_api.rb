module Google
  class WeatherApi
    FORECAST_DAYS = 10

    attr_reader :client

    class Error < BaseError; end

    class << self
      def current_conditions(latitude:, longitude:, zip_code:, nearby_zip_codes: nil)
        self.new.current_conditions(latitude:, longitude:, zip_code:, nearby_zip_codes:)
      end

      def forecast_days(latitude:, longitude:, zip_code:, nearby_zip_codes: nil)
        self.new.forecast_days(latitude:, longitude:, zip_code:, nearby_zip_codes:)
      end
    end

    def initialize
      @client = WeatherClient.new
    end

    def current_conditions(latitude:, longitude:, zip_code:, nearby_zip_codes: nil)
      path = 'currentConditions:lookup'
      query = location_query(latitude, longitude)
      cache_key = select_cache_key('weather_current_conditions', zip_code, nearby_zip_codes)

      parse_current_conditions(client.get(path, query:, cache_key:))
    rescue => e
      raise Error.new(
        e.class == client.class::Error ? e.message : "#{self.class.name} current conditions error: #{e.message}",
        status: e.try(:status),
        back_trace: e.backtrace
      )
    end

    def forecast_days(latitude:, longitude:, zip_code:, nearby_zip_codes: nil)
      path = 'forecast/days:lookup'
      query = location_query(latitude, longitude).merge(days: FORECAST_DAYS, pageSize: FORECAST_DAYS)
      cache_key = select_cache_key('weather_forecast_days', zip_code, nearby_zip_codes)

      parse_forecast_days(client.get(path, query:, cache_key:))
    rescue => e
      raise Error.new(
        e.class == client.class::Error ? e.message : "#{self.class.name} forecast days error: #{e.message}",
        status: e.try(:status),
        back_trace: e.backtrace
      )
    end

    private

    def select_cache_key(prefix, zip_code, nearby_zip_codes)
      [ zip_code, nearby_zip_codes ].flatten.uniq.each do |code|
        cache_key = "#{prefix}_#{code}"

        return cache_key if Rails.cache.exist?(cache_key)
      end

      "#{prefix}_#{zip_code}"
    end

    def location_query(latitude, longitude)
      {
        'location.latitude' => latitude,
        'location.longitude' => longitude
      }
    end

    # => { description:, icon_base_uri:, temperature: { degrees:, unit: }, feels_like_temperature:, relative_humidity:, uv_index:, cloud_cover:, wind_speed: { value:, unit: }, cached: }
    def parse_current_conditions(data)
      raise Error, 'not found' if data.blank?

      {
        description: data.dig(:weather_condition, :description, :text),
        icon_base_uri: data.dig(:weather_condition, :icon_base_uri),
        temperature: data[:temperature],
        feels_like_temperature: data[:feels_like_temperature],
        relative_humidity: data[:relative_humidity],
        uv_index: data[:uv_index],
        cloud_cover: data[:cloud_cover],
        wind_speed: data.dig(:wind, :speed),
        cached: data[:cached]
      }
    end

    # => { days: [{ date: { year:, month:, day: }, description:, icon_base_uri:, min_temperature:, max_temperature: }], cached: }
    def parse_forecast_days(data)
      raise Error, 'not found' if data.blank?

      days = Array(data[:forecast_days]).map do |day|
        {
          date: day[:display_date],
          description: day.dig(:daytime_forecast, :weather_condition, :description, :text),
          icon_base_uri: day.dig(:daytime_forecast, :weather_condition, :icon_base_uri),
          min_temperature: day[:min_temperature],
          max_temperature: day[:max_temperature]
        }
      end

      { days:, cached: data[:cached] }
    end
  end
end
