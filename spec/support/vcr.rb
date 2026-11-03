require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join('spec/fixtures/vcr_cassettes').to_s
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = { record: :once, match_requests_on: %i[method uri] }

  # Never write real API keys to cassettes
  %i[GOOGLE_PLACE_API_KEY GOOGLE_WEATHER_API_KEY GOOGLE_GEOCODING_API_KEY].each do |name|
    config.filter_sensitive_data("<#{name}>") { Rails.application.credentials.public_send(name) }
  end
end
