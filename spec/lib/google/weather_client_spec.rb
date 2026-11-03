require 'rails_helper'

RSpec.describe Google::WeatherClient do
  subject(:client) { described_class.new }

  let(:path) { 'currentConditions:lookup' }
  let(:options) { { query: { 'location.latitude' => 41.8857, 'location.longitude' => -87.6181 } } } # Chicago, 60601
  let(:request_url) { %r{\Ahttps://weather\.googleapis\.com/v1/currentConditions:lookup} }
  let(:service_name) { 'Google Weather Client' }
  let(:cassette_prefix) { 'google/weather_client' }

  describe '#get' do
    it 'returns the current conditions with snake_case keys' do
      VCR.use_cassette("#{cassette_prefix}/get_current_conditions") do
        result = client.get(path, **options)

        expect(result[:cached]).to be(false)
        expect(result[:temperature]).to include(:degrees, :unit)
        expect(result[:weather_condition]).to include(:icon_base_uri)
      end
    end

    it 'sends the API key in the X-Goog-Api-Key header, not in the URL' do
      VCR.turned_off do
        allow(client).to receive(:api_key).and_return('SPEC_API_KEY')
        stub_request(:get, request_url).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        client.get(path, **options)

        expect(a_request(:get, request_url).with(headers: { 'X-Goog-Api-Key' => 'SPEC_API_KEY' })).to have_been_made
        expect(a_request(:get, /[?&]key=/)).not_to have_been_made
      end
    end
  end

  it_behaves_like 'Google API client'
end
