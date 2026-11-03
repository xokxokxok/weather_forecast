module Google
  class PlaceApi
    PLACE_DETAILS_FIELDS = %w[
      id
      displayName
      formattedAddress
      addressComponents
      location
      shortFormattedAddress
      types
    ].join(',').freeze

    class Error < BaseError; end

    attr_reader :client

    class << self
      def autocomplete_address(input, session_token: nil)
        self.new.autocomplete_address(input, session_token:)
      end

      def place_details(place_id, session_token: nil)
        self.new.place_details(place_id, session_token:)
      end
    end

    def initialize
      @client = PlaceClient.new
    end

    def autocomplete_address(input, session_token: nil)
      path = 'places:autocomplete'
      body = {
        input:,
        sessionToken: session_token
      }

      parse_autocomplete_address(client.post(path, body:), session_token)
    rescue => e
      raise Error.new(
        e.class == client.class::Error ? e.message : "#{self.class.name} place autocomplete error: #{e.message}",
        status: e.try(:status),
        back_trace: e.backtrace
      )
    end

    def place_details(place_id, session_token:)
      path = "places/#{normalize_place_id(place_id)}"
      cache_key = path
      headers = { 'X-Goog-FieldMask' => PLACE_DETAILS_FIELDS }
      query = { session_token: }

      parse_place_details(client.get(path, query:, headers:, cache_key:))
    rescue => e
      raise Error.new(
        e.class == client.class::Error ? e.message : "#{self.class.name} place details error: #{e.message}",
        status: e.try(:status),
        back_trace: e.backtrace
      )
    end

    private

    def normalize_place_id(place_id)
      place_id.to_s.delete_prefix('places/')
    end

    # => { session_token:, locations: [{ place_id:, address: }] }
    def parse_autocomplete_address(data, session_token)
      locations = data&.dig(:suggestions)&.filter_map do |suggestion|
        prediction = suggestion[:place_prediction]
        next if prediction.blank? || prediction[:place_id].blank?

        {
          place_id: prediction[:place_id],
          address: prediction.dig(:text, :text).presence || prediction[:place_id]
        }
      end

      { session_token:, locations: }
    end

    # => { place_id:, name:, address:, short_address:, zip_code:, location: { latitude:, longitude: }, types: }
    def parse_place_details(data)
      raise Error, 'place not found' if data.blank?

      zip_code_component = data[:address_components].find { |c| c[:types].include?('postal_code') }

      {
        place_id: data[:id],
        name: data.dig(:display_name, :text),
        address: data[:formatted_address],
        short_address: data[:short_formatted_address],
        zip_code: zip_code_component&.dig(:short_text),
        location: data[:location],
        types: data[:types]
      }
    end
  end
end
