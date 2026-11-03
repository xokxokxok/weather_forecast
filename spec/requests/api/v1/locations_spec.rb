require 'rails_helper'

RSpec.describe Api::V1::LocationsController, type: :request do
  let(:session_token) { 'spec-session-token' }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  def stub_api_keys
    allow_any_instance_of(Google::PlaceClient).to receive(:api_key).and_return('SPEC_API_KEY')
    allow_any_instance_of(Google::GeocodingClient).to receive(:api_key).and_return('SPEC_API_KEY')
  end

  describe 'GET /api/v1/locations' do
    it 'returns the suggested locations' do
      VCR.use_cassette('api/v1/locations/index') do
        get '/api/v1/locations', params: { q: { input: '90210', session_token: } }
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['session_token']).to eq(session_token)
      expect(response.parsed_body['locations']).to be_present
      expect(response.parsed_body['locations']).to all(include('place_id', 'address'))
    end

    it 'returns bad_gateway when the Places API fails' do
      VCR.turned_off do
        stub_api_keys
        stub_request(:post, 'https://places.googleapis.com/v1/places:autocomplete').to_return(status: 500, body: '{}', headers: json_headers)

        get '/api/v1/locations', params: { q: { input: '90210', session_token: } }
      end

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body).to eq('error' => 'Google Place Client Error code: 500')
    end
  end

  describe 'GET /api/v1/locations/:id' do
    let(:place_details_url) { %r{\Ahttps://places\.googleapis\.com/v1/places/} }
    let(:geocoding_url) { %r{\Ahttps://geocode\.googleapis\.com/v4/geocode/location} }

    before { allow(Google::GeocodingApi).to receive(:nearby_zip_codes).and_call_original }

    context 'when the place details have a zip code' do
      let(:place_id) { 'ChIJ7xfS-zW8woARXNkAJzX5Hs8' } # Beverly Hills, CA 90210

      it 'returns the place zip code without calling the Geocoding API' do
        VCR.use_cassette('api/v1/locations/show_with_zip_code') do
          get "/api/v1/locations/#{place_id}", params: { q: { session_token: } }
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('place_id' => place_id, 'zip_code' => '90210')
        expect(response.parsed_body).not_to have_key('nearby_zip_codes')
        expect(Google::GeocodingApi).not_to have_received(:nearby_zip_codes)
      end
    end

    context 'when the place details have no zip code' do
      # Southwark Park Road, London, UK (a route: no postal_code component)
      let(:place_id) { 'Eh9Tb3V0aHdhcmsgUGFyayBSb2FkLCBMb25kb24sIFVLIi4qLAoUChIJN3JXaz4DdkgR9pWg552-yEsSFAoSCfPzF7dbG3ZIEQqyADl5LpFJ' }

      it 'uses the nearest zip code from the Geocoding API and returns the others as nearby_zip_codes' do
        VCR.use_cassette('api/v1/locations/show_without_zip_code') do
          get "/api/v1/locations/#{place_id}", params: { q: { session_token: } }
        end

        expect(response).to have_http_status(:ok)
        expect(Google::GeocodingApi).to have_received(:nearby_zip_codes).once
        expect(response.parsed_body['zip_code']).to be_present
        expect(response.parsed_body['nearby_zip_codes']).to be_an(Array)
        expect(response.parsed_body['nearby_zip_codes']).not_to include(response.parsed_body['zip_code'])
      end
    end

    context 'when the APIs fail' do
      let(:place_id) { 'spec-place-id' }
      let(:place_without_zip_code) do
        {
          id: place_id,
          formattedAddress: 'Spec Road, London, UK',
          addressComponents: [ { longText: 'London', shortText: 'London', types: [ 'postal_town' ] } ],
          location: { latitude: 51.4962989, longitude: -0.0482742 },
          types: [ 'route' ]
        }.to_json
      end

      around { |example| VCR.turned_off { example.run } }

      before { stub_api_keys }

      it 'returns bad_gateway when the Places API (first request) fails, without calling the Geocoding API' do
        stub_request(:get, place_details_url).to_return(status: 500, body: '{}', headers: json_headers)

        get "/api/v1/locations/#{place_id}", params: { q: { session_token: } }

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq('error' => 'Google Place Client Error code: 500')
        expect(Google::GeocodingApi).not_to have_received(:nearby_zip_codes)
      end

      it 'returns bad_gateway when the Places API succeeds without zip code and the Geocoding API (second request) fails' do
        stub_request(:get, place_details_url).to_return(status: 200, body: place_without_zip_code, headers: json_headers)
        stub_request(:get, geocoding_url).to_return(status: 500, body: '{}', headers: json_headers)

        get "/api/v1/locations/#{place_id}", params: { q: { session_token: } }

        expect(Google::GeocodingApi).to have_received(:nearby_zip_codes).once
        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq('error' => 'Google Geocoding Client Error code: 500')
      end
    end

    context 'when required params are missing' do
      it 'returns bad_request without session_token' do
        get '/api/v1/locations/any-place-id', params: { q: { input: 'ignored' } }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq('error' => 'place_id and session_token are required')
      end

      it 'returns bad_request without any query param' do
        get '/api/v1/locations/any-place-id'

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq('error' => 'place_id and session_token are required')
      end
    end
  end
end
