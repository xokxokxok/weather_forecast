require 'rails_helper'

RSpec.describe Google::PlaceClient do
  subject(:client) { described_class.new }

  let(:place_id) { 'ChIJ7xfS-zW8woARXNkAJzX5Hs8' } # Beverly Hills, CA 90210
  let(:path) { "places/#{place_id}" }
  let(:options) { { headers: { 'X-Goog-FieldMask' => 'id,formattedAddress,addressComponents,location' } } }
  let(:request_url) { %r{\Ahttps://places\.googleapis\.com/v1/places/} }
  let(:service_name) { 'Google Place Client' }
  let(:cassette_prefix) { 'google/place_client' }

  describe '#get' do
    it 'returns the place details with snake_case keys' do
      VCR.use_cassette("#{cassette_prefix}/get_place_details") do
        result = client.get(path, **options)

        expect(result).to include(id: place_id, cached: false)
        expect(result[:formatted_address]).to include('90210')
        expect(result[:location]).to include(:latitude, :longitude)
        expect(result[:address_components]).to include(a_hash_including(types: include('postal_code')))
      end
    end
  end

  describe '#post' do
    it 'returns autocomplete suggestions' do
      VCR.use_cassette("#{cassette_prefix}/post_autocomplete") do
        result = client.post('places:autocomplete', body: { input: '90210', includedPrimaryTypes: %w[postal_code] })

        expect(result[:cached]).to be(false)
        expect(result[:suggestions]).to be_present
        expect(result.dig(:suggestions, 0, :place_prediction, :place_id)).to be_present
      end
    end
  end

  it_behaves_like 'Google API client'
end
