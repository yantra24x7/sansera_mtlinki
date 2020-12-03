require "will_paginate/mongoid"
require 'will_paginate/array'
module Api
  module V1
    class ApplicationController < ActionController::API
        include ActionController::Serialization
        before_action :authenticate_request
        attr_reader :current_user
        attr_reader :current_db
        include ExceptionHandler
      private

      def authenticate_request
        @current_user = AuthorizeApiRequest.call(request.headers).result
        #@db = Mongo::Client.new('mongodb://fanuc:123456!@27.100.25.50:27017/MTLINKi')
        #db = Mongo::Connection.new("27.100.25.50" , 27017 ).db("MTLINKi")
        require 'mongo'
        #@current_db = Mongo::Client.new([ '27.100.25.50:27017' ], :database => 'MTLINKi', :username=> 'fanuc', :password=> '123456')
        @current_db = Mongo::Client.new([ '0.0.0.0:27017' ], :database => 'MTLINKi', :username=> 'dbuser', :password=> 'mani')
        #byebug
        #@current_db = @db.authenticate("fanuc","123456")
        
        #@db = Mongo::Client.new('mongodb://dbuser:mani!@localhost:27017/MTLINKi')
        #byebug
        #db = Mongo::Connection.new("27.100.25.50", 27017).db("MTLINKi")
        #byebug
        #byebug
        #session_hash = {"database" => "testmongo", "hosts" => ["127.0.0.1:3003"], "username" => "testuser", "password" => "test_password"}
        #Mongoid::Config.sessions[:mongo_dynamic] = session_hash
        render json: { error: 'Not Authorized' }, status: 401 unless @current_user.present?
      end


    end
  end
end
