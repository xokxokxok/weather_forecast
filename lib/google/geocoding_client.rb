module Google
  class GeocodingClient < BaseClient
    BASE_URI = 'https://geocode.googleapis.com/v4'
    CACHE_LIFETIME = 1.day
    API_KEY_NAME = :GOOGLE_GEOCODING_API_KEY
    SERVICE_NAME = 'Google Geocoding Client'

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
