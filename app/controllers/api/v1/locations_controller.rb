module Api
  module V1
    class LocationsController < ::Api::ApplicationController
      def index
        response = place_api.autocomplete_address(input, session_token:)
        options = build_options(response)

        render json: { session_token:, options: }
      rescue Google::PlaceClient::Error, Google::PlaceApi::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def show
        if place_id.blank? || session_token.blank?
          render json: { error: 'place_id and session_token are required' }, status: :bad_request
          return
        end

        details = place_api.place_details(place_id, session_token:)
        render json: details
      rescue Google::PlaceClient::Error, Google::PlaceApi::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def place_api
        @place_api ||= Google::PlaceApi.new
      end

      def input
        @input ||= query_params[:input]
      end

      def place_id
        @place_id ||= params[:id]
      end

      def session_token
        @session_token ||= query_params[:session_token]
      end

      def build_options(response)
        Array(response[:suggestions]).filter_map do |suggestion|
          prediction = suggestion[:place_prediction]
          next unless prediction

          {
            value: prediction[:place_id],
            label: prediction.dig(:text, :text) || prediction[:place_id]
          }
        end
      end
    end
  end
end
