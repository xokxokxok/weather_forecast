require 'rails_helper'

RSpec.describe Google::PlaceApi do
  let(:session_token) { 'spec-session-token' }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  describe '.autocomplete_address' do
    let(:request_url) { 'https://places.googleapis.com/v1/places:autocomplete' }

    it 'returns the session token and the suggested locations' do
      VCR.use_cassette('google/place_api/autocomplete_address') do
        result = described_class.autocomplete_address('90210', session_token:)

        expect(result[:session_token]).to eq(session_token)
        expect(result[:locations]).to be_present
        expect(result[:locations]).to all(include(:place_id, :address))
        expect(result[:locations].first[:address]).to include('90210')
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow_any_instance_of(Google::PlaceClient).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'wraps the client error in Google::PlaceApi::Error with the client message and status' do
        stub_request(:post, request_url).to_return(status: 500, body: '{}', headers: json_headers)

        expect { described_class.autocomplete_address('90210', session_token:) }
          .to raise_error(described_class::Error, 'Google Place Client Error code: 500') { |error| expect(error.status).to eq(:bad_gateway) }
      end

      it 'raises Google::PlaceApi::Error when the response cannot be parsed' do
        stub_request(:post, request_url).to_return(status: 200, body: '{"suggestions": ["invalid"]}', headers: json_headers)

        expect { described_class.autocomplete_address('90210', session_token:) }
          .to raise_error(described_class::Error, /\AGoogle::PlaceApi place autocomplete error: /)
      end
    end
  end

  describe '.place_details' do
    let(:place_id) { 'ChIJ7xfS-zW8woARXNkAJzX5Hs8' } # Beverly Hills, CA 90210
    let(:request_url) { %r{\Ahttps://places\.googleapis\.com/v1/places/#{place_id}} }

    it 'returns the place details with the zip code' do
      VCR.use_cassette('google/place_api/place_details') do
        result = described_class.place_details(place_id, session_token:)

        expect(result).to include(place_id:, zip_code: '90210')
        expect(result[:address]).to include('Beverly Hills')
        expect(result[:location]).to include(:latitude, :longitude)
        expect(result[:types]).to be_present
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow_any_instance_of(Google::PlaceClient).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'wraps the client error in Google::PlaceApi::Error with the client message and status' do
        stub_request(:get, request_url).to_return(status: 500, body: '{}', headers: json_headers)

        expect { described_class.place_details(place_id, session_token:) }
          .to raise_error(described_class::Error, 'Google Place Client Error code: 500') { |error| expect(error.status).to eq(:bad_gateway) }
      end

      it 'raises Google::PlaceApi::Error when the response cannot be parsed' do
        stub_request(:get, request_url).to_return(status: 200, body: '{"id": "invalid"}', headers: json_headers)

        expect { described_class.place_details(place_id, session_token:) }
          .to raise_error(described_class::Error, /\AGoogle::PlaceApi place details error: /)
      end
    end
  end
end
