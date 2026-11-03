require 'rails_helper'

RSpec.describe Google::GeocodingApi do
  let(:address) { 'Southwark Park Road, London, UK' }
  let(:coordinates) { { latitude: 51.4962989, longitude: -0.0482742 } }
  let(:request_url) { %r{\Ahttps://geocode\.googleapis\.com/v4/geocode/location} }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  describe '.nearby_zip_codes' do
    it 'returns the zip codes within the microclimate distance, nearest first' do
      VCR.use_cassette('google/geocoding_api/nearby_zip_codes') do
        result = described_class.nearby_zip_codes(address, **coordinates)

        expect(result).to eq([ 'SE16', 'SE16 7LL' ])
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow_any_instance_of(Google::GeocodingClient).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'wraps the client error in Google::GeocodingApi::Error with the client message and status' do
        stub_request(:get, request_url).to_return(status: 500, body: '{}', headers: json_headers)

        expect { described_class.nearby_zip_codes(address, **coordinates) }
          .to raise_error(described_class::Error, 'Google Geocoding Client Error code: 500') { |error| expect(error.status).to eq(:bad_gateway) }
      end

      it 'raises Google::GeocodingApi::Error when the response cannot be parsed' do
        body = { results: [ { location: { latitude: 51.4963, longitude: -0.0483 } } ] }.to_json
        stub_request(:get, request_url).to_return(status: 200, body:, headers: json_headers)

        expect { described_class.nearby_zip_codes(address, **coordinates) }
          .to raise_error(described_class::Error, /\AGoogle::GeocodingApi nearby zip codes error: /)
      end
    end
  end
end
