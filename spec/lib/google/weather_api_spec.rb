require 'rails_helper'

RSpec.describe Google::WeatherApi do
  let(:coordinates) { { latitude: 41.8857, longitude: -87.6181 } } # Chicago, 60601
  let(:zip_code) { '60601' }
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  describe '.current_conditions' do
    let(:request_url) { %r{\Ahttps://weather\.googleapis\.com/v1/currentConditions:lookup} }

    it 'returns the current conditions' do
      VCR.use_cassette('google/weather_api/current_conditions') do
        result = described_class.current_conditions(**coordinates, zip_code:)

        expect(result[:cached]).to be(false)
        expect(result[:temperature]).to include(:degrees, :unit)
        expect(result[:feels_like_temperature]).to include(:degrees, :unit)
        expect(result[:description]).to be_present
        expect(result[:icon_base_uri]).to start_with('https://')
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow_any_instance_of(Google::WeatherClient).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'wraps the client error in Google::WeatherApi::Error with the client message and status' do
        stub_request(:get, request_url).to_return(status: 500, body: '{}', headers: json_headers)

        expect { described_class.current_conditions(**coordinates, zip_code:) }
          .to raise_error(described_class::Error, 'Google Weather Client Error code: 500') { |error| expect(error.status).to eq(:bad_gateway) }
      end

      it 'raises Google::WeatherApi::Error when the response cannot be parsed' do
        stub_request(:get, request_url).to_return(status: 200, body: '{"weatherCondition": "invalid"}', headers: json_headers)

        expect { described_class.current_conditions(**coordinates, zip_code:) }
          .to raise_error(described_class::Error, /\AGoogle::WeatherApi current conditions error: /)
      end
    end
  end

  describe '.forecast_days' do
    let(:request_url) { %r{\Ahttps://weather\.googleapis\.com/v1/forecast/days:lookup} }

    it 'returns the 10-day forecast' do
      VCR.use_cassette('google/weather_api/forecast_days') do
        result = described_class.forecast_days(**coordinates, zip_code:)

        expect(result[:cached]).to be(false)
        expect(result[:days].size).to eq(described_class::FORECAST_DAYS)
        expect(result[:days]).to all(include(date: include(:year, :month, :day)))
        expect(result[:days].first).to include(:description, :icon_base_uri, :min_temperature, :max_temperature)
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow_any_instance_of(Google::WeatherClient).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'wraps the client error in Google::WeatherApi::Error with the client message and status' do
        stub_request(:get, request_url).to_return(status: 500, body: '{}', headers: json_headers)

        expect { described_class.forecast_days(**coordinates, zip_code:) }
          .to raise_error(described_class::Error, 'Google Weather Client Error code: 500') { |error| expect(error.status).to eq(:bad_gateway) }
      end

      it 'raises Google::WeatherApi::Error when the response cannot be parsed' do
        stub_request(:get, request_url).to_return(status: 200, body: '{"forecastDays": ["invalid"]}', headers: json_headers)

        expect { described_class.forecast_days(**coordinates, zip_code:) }
          .to raise_error(described_class::Error, /\AGoogle::WeatherApi forecast days error: /)
      end
    end
  end
end
