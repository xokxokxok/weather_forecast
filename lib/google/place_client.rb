module Google
  class PlaceClient < BaseClient
    BASE_URI = 'https://places.googleapis.com/v1'
    CACHE_LIFETIME = 1.day
    API_KEY_NAME = :GOOGLE_PLACE_API_KEY
    SERVICE_NAME = 'Google Place Client'

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
