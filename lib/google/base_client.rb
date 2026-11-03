module Google
  class BaseClient
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    def get(path, query: nil, headers: nil, cache_key: nil)
      request(:get, path, query:, headers:, cache_key:)
    end

    def post(path, query: nil, headers: nil, body: nil, cache_key: nil)
      request(:post, path, query:, headers:, body:, cache_key:)
    end

    private

    def cache_lifetime
      raise NotImplementedError
    end

    def base_uri
      raise NotImplementedError
    end

    def api_key_name
      raise NotImplementedError
    end

    def service_name
      raise NotImplementedError
    end

    def error_class
      raise NotImplementedError
    end

    def api_key
      @api_key ||= begin
        api_key = Rails.application.credentials.public_send(api_key_name)
        raise error_class.new("#{api_key_name} not found in credentials", status: :internal_server_error) if api_key.blank?
        api_key
      end
    end

    # FlatParamsEncoder: repeated parameters (e.g. types=a&types=b) are sent without the "[]" suffix.
    # The json request middleware encodes Hash bodies and sets Content-Type: application/json.
    def connection
      @connection ||= Faraday.new(request: { open_timeout: OPEN_TIMEOUT, timeout: READ_TIMEOUT, params_encoder: Faraday::FlatParamsEncoder }) do |faraday|
        faraday.request :json
        faraday.response :json
      end
    end

    def request(method, path, query: nil, headers: nil, body: nil, cache_key: nil)
      url = "#{base_uri}/#{path}"

      options = {
        query: build_query(query),
        headers: build_headers(headers),
        body: body&.compact_blank
      }

      return make_request(method, url, options).merge(cached: false) if cache_key.blank?

      cached = true

      data = Rails.cache.fetch(cache_key, skip_nil: true, expires_in: cache_lifetime) do
        cached = false
        make_request(method, url, options)
      end

      data.merge(cached:)
    end

    def make_request(method, url, options)
      response = connection.run_request(method, url, options[:body], options[:headers]) do |request|
        request.params.update(options[:query])
      end

      raise_response_error(response) unless response.success?
      raise error_class, "#{service_name} returned an invalid response" unless response.body.is_a?(Hash)

      parse_response(response.body)
    rescue Faraday::TimeoutError
      raise error_class.new("#{service_name} read timeout", status: :gateway_timeout)
    rescue Faraday::ConnectionFailed => e
      raise error_class.new("#{service_name} connection timeout", status: :gateway_timeout) if e.wrapped_exception.is_a?(Net::OpenTimeout)

      raise error_class.new("#{service_name} is unreachable", status: :service_unavailable)
    rescue Faraday::ParsingError
      raise error_class, "#{service_name} returned an invalid response"
    end

    def raise_response_error(response)
      status = response.status == 429 ? :too_many_requests : :bad_gateway

      raise error_class.new("#{service_name} Error code: #{response.status}", status:)
    end

    def build_headers(headers)
      headers = headers.presence || {}

      headers['X-Goog-Api-Key'] = api_key

      headers
    end

    def build_query(query)
      (query.presence || {}).compact_blank
    end

    def parse_response(parsed_response)
      data = { data: parsed_response }

      data = data.deep_transform_keys { |key| key.to_s.underscore.to_sym }

      data[:data]
    end
  end
end
