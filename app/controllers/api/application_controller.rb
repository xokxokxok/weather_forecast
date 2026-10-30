module Api
  class ApplicationController < ActionController::API
    include ActionController::MimeResponds

    private

    def query_params
      params[:q]
    end

    def query_string
      params[:q].to_s.strip
    end
  end
end