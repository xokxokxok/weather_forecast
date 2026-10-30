module Api
  module V1
    class WeatherConditionsController < ::Api::ApplicationController
      def index
        zip_code_and_coordinates_present?

        forecast = weather_api.forecast_days(**coordinates, zip_code:)
        render json: forecast
      rescue Google::WeatherClient::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def show
        zip_code_and_coordinates_present?

        current = weather_api.current_conditions(**coordinates, zip_code:)
        render json: current
      rescue Google::WeatherClient::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def weather_api
        @weather_api ||= Google::WeatherApi.new
      end

      def zip_code_and_coordinates_present?
        if zip_code.blank?
          render json: { error: "zip_code is required" }, status: :bad_request
          return
        end

        if coordinates.blank?
          render json: { error: "latitude and longitude are required" }, status: :bad_request
          return
        end
      end

      def coordinates
        latitude = params[:latitude].presence
        longitude = params[:longitude].presence
        return nil unless latitude && longitude

        { latitude: latitude.to_f, longitude: longitude.to_f }
      end

      def zip_code
        params[:zip_code]
      end
    end
  end
end
