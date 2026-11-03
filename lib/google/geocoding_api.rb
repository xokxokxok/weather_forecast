module Google
  class GeocodingApi
    DEFAULT_TYPE = 'postal_code'.freeze
    MICROCLIMATE_DISTANCE_IN_METERS = 5000
    EARTH_RADIUS_IN_METERS = 6_371_000
    NEARBY_ZIP_CODES_FIELDS = %w[
      results.addressComponents
      results.location
    ].join(',').freeze

    class Error < BaseError; end

    attr_reader :client

    class << self
      def nearby_zip_codes(formatted_address, latitude:, longitude:)
        self.new.nearby_zip_codes(formatted_address, latitude:, longitude:)
      end
    end

    def initialize
      @client = GeocodingClient.new
    end

    # Reverse geocoding: Gets all possible zipcodes
    # => { zip_codes: [...] } nearest first
    def nearby_zip_codes(formatted_address, latitude:, longitude:)
      path = 'geocode/location'
      cache_key = "geocoding_nearby_zip_codes_#{formatted_address.parameterize.underscore}"
      headers = { 'X-Goog-FieldMask' => NEARBY_ZIP_CODES_FIELDS }
      query = {
        'location.latitude' => latitude,
        'location.longitude' => longitude,
        'types' => [ 'postal_code' ]
      }

      parse_nearby_zip_codes(client.get(path, query:, headers:, cache_key:), latitude, longitude)
    rescue => e
      raise Error.new(
        e.class == client.class::Error ? e.message : "#{self.class.name} nearby zip codes error: #{e.message}",
        status: e.try(:status),
        back_trace: e.backtrace
      )
    end

    private

    # Adds :distance_in_meters to each result
    def calculate_distances(results, latitude, longitude)
      results.each do |result|
        result_latitude = result.dig(:location, :latitude)
        result_longitude = result.dig(:location, :longitude)

        next if result_latitude.blank? || result_longitude.blank?

        lat1 = latitude.to_f * Math::PI / 180
        lat2 = result_latitude.to_f * Math::PI / 180
        delta_lat = lat2 - lat1
        delta_lng = (result_longitude.to_f - longitude.to_f) * Math::PI / 180

        a = Math.sin(delta_lat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(delta_lng / 2)**2
        distance = 2 * EARTH_RADIUS_IN_METERS * Math.asin(Math.sqrt([ a, 1.0 ].min))

        result[:distance] = distance
      end
    end

    def parse_nearby_zip_codes(data, latitude, longitude)
      raise Error, 'geocode location not found' if data.blank? || data[:results].blank?

      calculate_distances(data[:results], latitude, longitude)

      data[:results].select! { |result| result[:distance].present? && result[:distance] <= MICROCLIMATE_DISTANCE_IN_METERS }
      data[:results].sort_by! { |result| result[:distance] }

      selected_results = data[:results].presence || [ data[:results].first ]

      zip_codes = selected_results.map do |result|
        zip_code_component = result[:address_components].find { |entry| entry[:types].include?(DEFAULT_TYPE) }

        zip_code_component && (zip_code_component[:short_text].presence || zip_code_component[:long_text])
      end.compact_blank

      raise Error, 'not a valid coordinates' if zip_codes.blank?

      zip_codes.uniq
    end
  end
end