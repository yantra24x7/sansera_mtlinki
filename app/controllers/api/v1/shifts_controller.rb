module Api
  module V1
    class ShiftsController < ApplicationController
      before_action :set_shift, only: [:show, :update, :destroy]
      before_action :auth_user, only: [:index, :show, :update, :destroy]
    def sansera_andon_board
      byebug
    end


      # GET /shifts
      def index
        @shifts = Shift.all

        render json: @shifts
      end

      # GET /shifts/1
      def show
        render json: @shift
      end

      # POST /shifts
      def create
     
      @shift = Shift.new(shift_params)
      all_shift = []
      shifts = Shift.all
      shifts.map do |ll|
      case
      when ll.start_day == '1' && ll.end_day == '1'
        all_shift << [ll.start_time.to_time..ll.end_time.to_time]
      when ll.start_day == '1' && ll.end_day == '2'
        all_shift <<  [ll.start_time.to_time..ll.end_time.to_time+1.day]
      else
        all_shift << [ll.start_time.to_time+1.day..ll.end_time.to_time+1.day]
      end
     end
 
     if @shift.start_day == "1" && @shift.end_day=="1"
       start_time = @shift.start_time.to_time
       end_time = @shift.end_time.to_time     
     elsif @shift.start_day == "1" && @shift.end_day=="2"
       start_time = @shift.start_time.to_time
       end_time = @shift.end_time.to_time+1.day
     else
       shift_time = @shift.start_time.to_time+1.day
       end_time = @shift.end_time.to_time+1.day
     end 
    shift_status = []
   all_shift.each do |aa|
     
     if aa.first.cover?(start_time) || aa.first.cover?(end_time)
       shift_status << true
     else
       shift_status << false
     end     
   end
 
if shift_status.include?(true)
render json: {msg: "Change Some Date or Day"}
else


       total_hour1 = params[:start_time].to_time.strftime("%p")=="PM" && params[:end_time].to_time.strftime("%p")=="AM" ?  Time.at((params[:end_time].to_time - 1.day) - params[:start_time].to_time).utc.strftime("%H:%M:%S") : Time.at(params[:end_time].to_time - params[:start_time].to_time).utc.strftime("%H:%M:%S")
     # @shift.total_hour.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }
#@shift.actual_working_without_b = @shifttransaction.actual_working_hours
        @shift.total_hour = (Time.parse(total_hour1).seconds_since_midnight).to_i
        @shift.break_time = (Time.parse(params[:break_time]).seconds_since_midnight).to_i
        @shift.actual_hour = (@shift.total_hour.to_i - @shift.break_time.to_i)
        if @shift.save
          render json: @shift#, status: :created, location: @shift
        else
          render json: @shift.errors, status: :unprocessable_entity
        end
      end
end
      # PATCH/PUT /shifts/1
      def update
        if @shift.update(shift_params)
          render json: @shift
        else
          render json: @shift.errors, status: :unprocessable_entity
        end
      end

      # DELETE /shifts/1
      def destroy
        status = @shift.destroy
        render json: {status: status}
      end

      private
        # Use callbacks to share common setup or constraints between actions.
        def set_shift
          @shift = Shift.find(params[:id])
        end
       
        def auth_user
         if @current_user.role == "Admin"
         else
          render json: "ok"
         end
        end
       
        # Only allow a trusted parameter "white list" through.
       
        def shift_params
          params.require(:shift).permit(:start_time, :end_time, :total_hour, :shift_no, :start_day, :end_day)
        end
    end
  end
end
