module Google
  class WeatherClient < BaseClient
    BASE_URI = 'https://weather.googleapis.com/v1'
    CACHE_LIFETIME = 30.minutes
    API_KEY_NAME = :GOOGLE_WEATHER_API_KEY
    SERVICE_NAME = 'Google Weather Client'

    class Error < BaseError; end

    private

    def base_uri
      BASE_URI
    end

    def cache_lifetime
      CACHE_LIFETIME
    end

    def api_key_name
      API_KEY_NAME
    end

    def service_name
      SERVICE_NAME
    end

    def error_class
      Error
    end
  end
end
