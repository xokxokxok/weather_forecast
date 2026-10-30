module Google
  class PlaceApi
    ADDRESS_PRIMARY_TYPES = %w[
      street_address
      route
      premise
      subpremise
      postal_code
    ].freeze

    PLACE_DETAILS_FIELDS = %w[
      id
      displayName
      formattedAddress
      addressComponents
      location
      shortFormattedAddress
      types
    ].join(',').freeze

    class Error < StandardError; end

    attr_reader :client

    def initialize(client: nil)
      @client = client.presence || PlaceClient.new
    end

    def autocomplete_address(input, session_token: nil)
      path = 'places:autocomplete'
      body = {
        input:,
        sessionToken: session_token,
        includedPrimaryTypes: ADDRESS_PRIMARY_TYPES
      }

      data = client.post(path, body:)

      data[:session_token] = session_token

      data
    end

    def place_details(place_id, session_token:)
      path = "places/#{normalize_place_id(place_id)}"
      cache_key = path
      headers = { 'X-Goog-FieldMask' => PLACE_DETAILS_FIELDS }
      query = { session_token: }

      client.get(path, query:, headers:, cache_key:)
    end

    private

    def parse_response(data)
      data.deep_sy_transform_keys { |key| key.to_s.underscore.to_sym }
    end

    def normalize_place_id(place_id)
      place_id.to_s.delete_prefix('places/')
    end
  end
end
