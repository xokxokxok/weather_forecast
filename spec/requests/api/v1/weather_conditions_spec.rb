require 'rails_helper'

RSpec.describe Api::V1::WeatherConditionsController, type: :request do
  let(:valid_params) { { latitude: 41.8857, longitude: -87.6181, zip_code: '60601' } } # Chicago
  let(:json_headers) { { 'Content-Type' => 'application/json' } }
  let(:missing_zip_code) { { 'error' => 'at least one of zip_code or nearby_zip_codes is required' } }
  let(:missing_coordinates) { { 'error' => 'latitude and longitude are required' } }

  shared_examples 'validates the required params' do
    it 'returns bad_request without zip_code' do
      get path, params: valid_params.except(:zip_code)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(missing_zip_code)
    end

    it 'returns bad_request without latitude' do
      get path, params: valid_params.except(:latitude)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(missing_coordinates)
    end

    it 'returns bad_request without longitude' do
      get path, params: valid_params.except(:longitude)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(missing_coordinates)
    end

    it 'returns bad_request without any param' do
      get path

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(missing_zip_code)
    end
  end

  shared_examples 'handles Weather API errors' do
    it 'returns bad_gateway when the Weather API fails' do
      VCR.turned_off do
        allow_any_instance_of(Google::WeatherClient).to receive(:api_key).and_return('SPEC_API_KEY')
        stub_request(:get, weather_url).to_return(status: 500, body: '{}', headers: json_headers)

        get path, params: valid_params
      end

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body).to eq('error' => 'Google Weather Client Error code: 500')
    end
  end

  describe 'GET /api/v1/weather_conditions (forecast days)' do
    let(:path) { '/api/v1/weather_conditions' }
    let(:weather_url) { %r{\Ahttps://weather\.googleapis\.com/v1/forecast/days:lookup} }

    it 'returns the 10-day forecast' do
      VCR.use_cassette('api/v1/weather_conditions/index') do
        get path, params: valid_params
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['cached']).to be(false)
      expect(response.parsed_body['days'].size).to eq(Google::WeatherApi::FORECAST_DAYS)
      expect(response.parsed_body['days']).to all(include('date', 'min_temperature', 'max_temperature'))
    end

    it 'accepts nearby_zip_codes as an array' do
      VCR.use_cassette('api/v1/weather_conditions/index') do
        get path, params: valid_params.merge(nearby_zip_codes: [ '60602', '60603' ])
      end

      expect(response).to have_http_status(:ok)
    end

    include_examples 'handles Weather API errors'
    include_examples 'validates the required params'
  end

  describe 'GET /api/v1/weather_conditions/current (current conditions)' do
    let(:path) { '/api/v1/weather_conditions/current' }
    let(:weather_url) { %r{\Ahttps://weather\.googleapis\.com/v1/currentConditions:lookup} }

    it 'returns the current conditions' do
      VCR.use_cassette('api/v1/weather_conditions/show') do
        get path, params: valid_params
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['cached']).to be(false)
      expect(response.parsed_body['temperature']).to include('degrees', 'unit')
      expect(response.parsed_body['description']).to be_present
    end

    include_examples 'handles Weather API errors'
    include_examples 'validates the required params'
  end
end
