module Api
  module V1
  	class UsersController < ApplicationController
      before_action :set_operator, only: [:show, :update, :destroy]
      skip_before_action :authenticate_request, only: %i[user_signup login identify_user verify_user password_updation tab_machine_list]


      def index
        @users = User.all
        render json: @users
      end

      def tab_machine_list
        data = []
        machine = L0Setting.pluck(:id, :L0Name)
        machine.each do |mac|
        data << { 
          id: mac[0],
          machine_name: mac[1]
        }
        end
        render json: data
      end

      def user_signup
        # @user = User.new(user_params)
        # @user = User.new(email: params[:email], password: params[:password])
        @user = User.new(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], password: params[:password], phone_no: params[:phone_no], dup_password: params[:password], isactive: false)
        if @user.save
          render json: @user#, status: :created, location: @user
        else
          render json: @user.errors#, status: :unprocessable_entity
        end
      end

      # GET /operators/1
      def show
        render json: @user
      end

      # PATCH/PUT /users/1
      def update
  # buebug
        if @user.update(user_params)
          render json: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # DELETE /operators/1
      def destroy
        byebug
        @user.destroy
        render json: "ok"
      end


      def test
        byebug
        a = L0Setting.all.count
        render json: {key: "ok", value: a}
      end

      def login
        authenticate params[:email], params[:password]
      end

      # GET users/verify_user (for verify the user by using email and phone_no)
      def verify_user
        if params[:email].present? && params[:phone_no].present?
          @user = User.find_by(email: params[:email], phone_no: params[:phone_no])
          if @user.present?
            render json: {status: true, user_id: @user.id}, status: :ok
          else
            render json: {error: 'Invalid phone no or Email ID'}, status: :unprocessable_entity
          end
        else
          render json: {message: "Must be enter the Email Id and phone no"}, status: :unprocessable_entity
        end
      end


      # GET users/password_updation (for update the new password)
      def password_updation
        user_id = params[:user_id]
        password = params[:password]
        if password.present?
          @password = User.find(params[:user_id]).update(password: params[:password], dup_password: params[:password])
          render json: {status: @password}, status: :ok
        else
          render json: { error: 'password can not be nil' }, status: :unauthorized
        end     
      end

      private

        # Use callbacks to share common setup or constraints between actions.
        def set_operator
          @user = User.find(params[:id])
        end
        
        def user_params
          params.require(:user).permit!#(:first_name, :last_name, :email, :password, :phone_no, :dup_password, :isactive)
        end

        def authenticate(email, password)
            command = AuthenticateUser.call(email, password)  
            if command.success?
              user_id = JsonWebToken.decode(command.result)["user_id"]
              user = User.find(user_id)
              render json: {
                access_token: command.result,
                message: 'Login Successful'
              }
            else
              render json: false#{ error: command.errors }, status: :unauthorized
            end
      end
  	end
  end
end
