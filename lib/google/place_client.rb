module Google
  class PlaceClient
    BASE_URI = 'https://places.googleapis.com/v1'
    CACHE_LIFETIME = 1.hour

    class Error < StandardError; end

    def initialize

    end

    def get(path, query: nil, headers: nil, cache_key: nil)
      request(:get, path, query:, headers:, cache_key:)
    end

    def post(path, query: nil, headers: nil, body: nil, cache_key: nil)
      request(:post, path, query:, headers:, body:, cache_key:)
    end

    private

    def api_key
      @api_key ||= begin
        api_key = Rails.application.credentials.GOOGLE_PLACE_API_KEY
        raise Error, 'GOOGLE_PLACE_API_KEY not found in credentials' if api_key.blank?
        api_key
      end
    end

    def request(method, path, query: nil, headers: nil, body: nil, cache_key: nil)
      url = "#{BASE_URI}/#{path}"

      options = {
        headers: build_headers(headers),
        query: build_query(query),
      }

      options[:body] = body.compact_blank.to_json if body

      if cache_key.present?
        Rails.cache.fetch(cache_key, force: cache_key.blank?, skip_nil: true, expires_in: CACHE_LIFETIME) do
          make_request(method, url, options)
        end
      else
        make_request(method, url, options)
      end
    end

    def make_request(method, url, options)
      response = HTTParty.public_send(method, url, options)

      code = response.response.code.to_i
      raise Error, "Google Place API Error code: #{code}" if code / 100 != 2

      parse_response(response.parsed_response)
    end

    def build_headers(headers)
      headers = headers.presence || {}

      headers['Content-Type'] = 'application/json'
      headers['X-Goog-Api-Key'] = api_key

      headers
    end

    def build_query(query)
      (query.presence || {}).compact_blank
    end

    def parse_response(parsed_response)
      data = { data: parsed_response }

      data = data.deep_transform_keys { |key| key.to_s.underscore.to_sym }

      data[:data]
    end
  end
end
