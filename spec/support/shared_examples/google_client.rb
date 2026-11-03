RSpec.shared_examples 'Google API client' do
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  def perform
    client.get(path, **options)
  end

  def expect_client_error(message, status)
    expect { perform }.to raise_error(described_class::Error, message) do |error|
      expect(error).to be_a(Google::BaseError)
      expect(error.status).to eq(status)
    end
  end

  describe 'error handling' do
    it 'raises internal_server_error when the API key is missing from credentials' do
      allow(client).to receive(:api_key_name).and_return(:MISSING_SPEC_API_KEY)

      expect_client_error('MISSING_SPEC_API_KEY not found in credentials', :internal_server_error)
    end

    it 'raises bad_gateway when Google rejects the API key' do
      allow(client).to receive(:api_key).and_return('INVALID_SPEC_API_KEY')

      VCR.use_cassette("#{cassette_prefix}/invalid_api_key") do
        expect_client_error("#{service_name} Error code: 400", :bad_gateway)
      end
    end

    context 'with stubbed HTTP responses' do
      around { |example| VCR.turned_off { example.run } }

      before { allow(client).to receive(:api_key).and_return('SPEC_API_KEY') }

      it 'raises too_many_requests when Google returns 429' do
        stub_request(:any, request_url).to_return(status: 429, body: '{}', headers: json_headers)

        expect_client_error("#{service_name} Error code: 429", :too_many_requests)
      end

      it 'raises bad_gateway when Google returns 5xx' do
        stub_request(:any, request_url).to_return(status: 503, body: '{}', headers: json_headers)

        expect_client_error("#{service_name} Error code: 503", :bad_gateway)
      end

      it 'raises gateway_timeout on read timeout' do
        stub_request(:any, request_url).to_raise(Net::ReadTimeout)

        expect_client_error("#{service_name} read timeout", :gateway_timeout)
      end

      it 'raises gateway_timeout on connection (open) timeout' do
        stub_request(:any, request_url).to_raise(Net::OpenTimeout)

        expect_client_error("#{service_name} connection timeout", :gateway_timeout)
      end

      it 'raises service_unavailable when the host is unreachable' do
        stub_request(:any, request_url).to_raise(Errno::ECONNREFUSED)

        expect_client_error("#{service_name} is unreachable", :service_unavailable)
      end

      it 'raises bad_gateway when the body is not valid JSON' do
        stub_request(:any, request_url).to_return(status: 200, body: 'not json', headers: json_headers)

        expect_client_error("#{service_name} returned an invalid response", :bad_gateway)
      end

      it 'raises bad_gateway when the JSON body is not an object' do
        stub_request(:any, request_url).to_return(status: 200, body: '[]', headers: json_headers)

        expect_client_error("#{service_name} returned an invalid response", :bad_gateway)
      end

      it 'returns cached: false then cached: true when a cache_key is given' do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        stub_request(:any, request_url).to_return(status: 200, body: '{"someValue": 1}', headers: json_headers)

        first = client.get(path, **options, cache_key: 'spec_cache_key')
        second = client.get(path, **options, cache_key: 'spec_cache_key')

        expect(first).to eq(some_value: 1, cached: false)
        expect(second).to eq(some_value: 1, cached: true)
        expect(a_request(:any, request_url)).to have_been_made.once
      end
    end
  end
end
