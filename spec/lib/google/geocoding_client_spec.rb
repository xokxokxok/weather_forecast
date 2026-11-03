require 'rails_helper'

RSpec.describe Google::GeocodingClient do
  subject(:client) { described_class.new }

  let(:path) { 'geocode/location' }
  let(:options) { { query: { 'location.latitude' => 51.4962989, 'location.longitude' => -0.0482742, 'types' => %w[postal_code] } } }
  let(:request_url) { %r{\Ahttps://geocode\.googleapis\.com/v4/geocode/location} }
  let(:service_name) { 'Google Geocoding Client' }
  let(:cassette_prefix) { 'google/geocoding_client' }

  describe '#get' do
    it 'returns only postal_code results with snake_case keys' do
      VCR.use_cassette("#{cassette_prefix}/get_nearby_zip_codes") do
        result = client.get(path, **options)

        expect(result[:cached]).to be(false)
        expect(result[:results]).to be_present
        expect(result[:results]).to all(include(types: include('postal_code'), location: include(:latitude, :longitude)))

        postal_code = result.dig(:results, 0, :address_components).find { |component| component[:types].include?('postal_code') }
        expect(postal_code).to include(long_text: 'SE16 7LL')
      end
    end

    it 'sends array params as repeated keys (types=a&types=b)' do
      uri = client.send(:connection).build_url("https://geocode.googleapis.com/v4/#{path}", 'types' => %w[postal_code route])

      expect(uri.query).to eq('types=postal_code&types=route')
    end
  end

  it_behaves_like 'Google API client'
end
