module Api
  module V1
    class WeatherConditionsController < ::Api::ApplicationController
      def index
        return if zip_code_or_coordinates_blank?

        forecast = Google::WeatherApi.forecast_days(**coordinates, zip_code:, nearby_zip_codes:)
        render json: forecast
      end

      def show
        return if zip_code_or_coordinates_blank?

        current = Google::WeatherApi.current_conditions(**coordinates, zip_code:, nearby_zip_codes:)
        render json: current
      end

      private

      def zip_code
        params[:zip_code].presence
      end

      def nearby_zip_codes
        params[:nearby_zip_codes].presence
      end

      def coordinates
        latitude = params[:latitude].presence
        longitude = params[:longitude].presence
        return nil unless latitude && longitude

        { latitude: latitude.to_f, longitude: longitude.to_f }
      end

      def zip_code_or_coordinates_blank?
        if zip_code.blank?
          render json: { error: 'at least one of zip_code or nearby_zip_codes is required' }, status: :bad_request
          return true
        end

        if coordinates.blank?
          render json: { error: 'latitude and longitude are required' }, status: :bad_request
          true
        end
      end
    end
  end
end
