require "will_paginate/mongoid"
require 'will_paginate/array'
module Api
  module V1
    class ApplicationController < ActionController::API
        include ActionController::Serialization
        before_action :authenticate_request
        after_action :track_action
        attr_reader :current_user
        attr_reader :current_db
        include ExceptionHandler
      private

      def authenticate_request
        @current_user = AuthorizeApiRequest.call(request.headers).result
        render json: { error: 'Not Authorized' }, status: 401 unless @current_user.present?
      end
     
      def current_user
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
      end

       def track_action
       # byebug
       
# ahoy.track "Ran action", request.path_parameters
        ahoy.authenticate(@current_user)
       # ahoy.track "user_id", @current_user
       end
    end
  end
end
