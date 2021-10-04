module Api
  module V1
    class ShiftsController < ApplicationController
      before_action :set_shift, only: [:show, :update, :destroy]
      before_action :auth_user, only: [:index, :show, :update, :destroy]

    def prev_dashboard
       date = params[:date]
       shift = Shift.where(shift_no: params[:shift_no]).first       
      
       case
        when shift.start_day == '1' && shift.end_day == '1'
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        when shift.start_day == '1' && shift.end_day == '2'
          if Time.now.strftime("%p") == "AM"
            start_time = (date+" "+shift.start_time).to_time-1.day
            end_time = (date+" "+shift.end_time).to_time
          else
            start_time = (date+" "+shift.start_time).to_time
            end_time = (date+" "+shift.end_time).to_time+1.day
          end
        else
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        end

      if @current_user.module == []
        report = Report.where(date: date, shift_num: params[:shift_no])
       else
        report = Report.where(date: date, shift_num: params[:shift_no], :line.in => @current_user.module)
       end
        
       if report.present?
        result_data = []
        machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time, :L1Name.in => report.pluck(:machine_name)).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}

        report.group_by{|d| d[:line]}.map do |key1,value1|
          over_all_effi = value1.pluck(:efficiency).map{|i| i.to_i}.sum/value1.count
          low_perfom = value1.group_by { |x| x[:efficiency] }.min.last.first
          low_per_machine = low_perfom.machine_name
          low_line = low_per_machine.split("-").first
          low_per_target = low_perfom.target
          low_per_actual = low_perfom.part_count
          
          low_per_run = ((low_per_actual/(end_time-start_time))*100).round(2)
      #    low_per_run = Time.at(low_perfom.run_time).utc.strftime("%H:%M:%S")
          low_per_idle = (((low_perfom.idle_time+low_perfom.alarm_time)/(end_time-start_time))*100).round(2)   
      #    low_per_idle = Time.at(low_perfom.idle_time+low_perfom.alarm_time).utc.strftime("%H:%M:%S")
          low_per_stop = ((low_perfom.disconnect/(end_time-start_time))*100).round(2)
      #     low_per_stop =  Time.at(low_perfom.disconnect).utc.strftime("%H:%M:%S")

          mac_list = value1.pluck(:machine_name)
         machine_status_list = []
          mac_list.each do |mc_list|
            last_rec = machine_log[mc_list]
            if last_rec.present?
              case
                when last_rec.last.value == "OPERATE"
                  m_status = "OPERATE"
                when last_rec.last.value == "DISCONNECT"
                  m_status = "DISCONNECT"
                else
                  m_status = "STOP"
                end
            else
               m_status = "DISCONNECT"
            end
              machine_status_list << {machine: mc_list, value: m_status}
          end
          result_data << {Line: low_line, eff: over_all_effi, low_perf_machine: low_perfom.machine_name, machine_list: value1.pluck(:machine_name), lpt: low_per_target, lpa: low_per_actual, status: machine_status_list, time: Time.now, show_time: Time.now, shift_no: params[:shift_no], low_per_run_time: low_per_run, low_per_idle_time: low_per_idle, low_per_stop_time: low_per_stop}
        end        
          render json: result_data
       else
        render json: {msg: "No Data Found"}
       end
  
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
         if @current_user.role == "Admin" || @current_user.role == "Supervisor" || @current_user.role == "QA"
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
