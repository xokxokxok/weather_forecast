module Api
  class ApplicationController < ActionController::API
    include ActionController::MimeResponds

    rescue_from Google::PlaceApi::Error, Google::GeocodingApi::Error, Google::WeatherApi::Error, with: :render_upstream_error

    private

    def render_upstream_error(error)
      render json: { error: error.message }, status: error.status
    end

    def query_params
      params[:q] || {}
    end
  end
end