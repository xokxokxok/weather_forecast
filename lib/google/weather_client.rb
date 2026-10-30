module Google
  class WeatherClient
    BASE_URI = 'https://weather.googleapis.com/v1'
    CACHE_LIFETIME = 30.minutes

    class Error < StandardError; end

    def get(path, query: nil, cache_key: nil)
      request(:get, path, query:, cache_key:)
    end

    private

    def api_key
      @api_key ||= begin
        api_key = Rails.application.credentials.GOOGLE_WEATHER_API_KEY
        raise Error, 'GOOGLE_WEATHER_API_KEY not found in credentials' if api_key.blank?
        api_key
      end
    end

    def request(method, path, query: nil, cache_key: nil)
      url = "#{BASE_URI}/#{path}"
      options = { query: build_query(query) }

      return make_request(method, url, options) if cache_key.blank?

      cached = true

      data = Rails.cache.fetch(cache_key, skip_nil: true, expires_in: CACHE_LIFETIME) do
        cached = false
        make_request(method, url, options)
      end

      data.merge(cached:)
    end

    def make_request(method, url, options)
      response = HTTParty.public_send(method, url, options)

      code = response.code.to_i
      raise Error, "Google Weather API Error code: #{code}" if code / 100 != 2

      parse_response(response.parsed_response)
    end

    def build_query(query)
      (query.presence || {}).compact_blank.merge(key: api_key)
    end

    def parse_response(parsed_response)
      data = { data: parsed_response }

      data = data.deep_transform_keys { |key| key.to_s.underscore.to_sym }

      data[:data]
    end
  end
end
