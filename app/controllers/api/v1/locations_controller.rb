module Api
  module V1
    class LocationsController < ::Api::ApplicationController
      def index
        render json: Google::PlaceApi.autocomplete_address(input, session_token:)
      end

      def show
        if place_id.blank? || session_token.blank?
          render json: { error: 'place_id and session_token are required' }, status: :bad_request
          return
        end

        details = Google::PlaceApi.place_details(place_id, session_token:)

        if details[:zip_code].blank?
          details[:nearby_zip_codes] = Google::GeocodingApi.nearby_zip_codes(
            details[:address],
            latitude: details[:location][:latitude],
            longitude: details[:location][:longitude]
          )
          details[:zip_code] = details[:nearby_zip_codes].shift
        end

        render json: details
      end

      private

      def input
        @input ||= query_params[:input]
      end

      def place_id
        @place_id ||= params[:id]
      end

      def session_token
        @session_token ||= query_params[:session_token]
      end
    end
  end
end