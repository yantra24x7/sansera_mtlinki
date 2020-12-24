module Api
  module V1
class OeeCalculationsController < ApplicationController
  before_action :set_oee_calculation, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request, only: %i[production_results_remarks production_results tab_shift_list oee_past_dashboard live_oee_tab live_production_part]
 
  # GET /oee_calculations
  def index
    @oee_calculations = OeeCalculation.all
    render json: @oee_calculations
  end

  def oee_machine_list
    data = []
    machines = L0Setting.pluck(:id, :L0Name)
    machines.each do |mac|
      data << {
        id: mac[0],
        name: mac[1]
      }
    end
    render json: data
  end

  def production_results
       
      date = params[:date].to_date.to_s
      shift = Shift.find_by(shift_no: params["shift_num"])
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


     result = ProductResultHistory.where(:L1Name.in => [params[:machine]], :enddate.gte => start_time, :updatedate.lte => end_time)
     result2 = result.select{|j| j["productresult"] != '0' && j["is_verified"] != true}
     page = params[:page].present? ? params[:page] : 1
     page_count = params[:per_page].present? ? params[:per_page] : 10
     result3_count = result2.count
     result3 = result2.paginate(:page => page, :per_page => page_count)

    render json: {parts: result3, count: result3_count}  

end

  def production_results_remarks
  # @production_results_remarks = ProductResultHistory.find(params[:production_result_id]).update(accept_count: params[:accept_count], reject_count: params[:reject_count])
   @production_results_remarks = ProductResultHistory.find(params[:production_result_id]).update(accept_count: params[:accept_count], is_verified: true)  
 render json: @production_results_remarks
  end

  def tab_shift_list
   @shifts = Shift.all
   render json: @shifts
  end

  def oee_past_dashboard
    
    availability_data = Report.where(date: params[:date], shift_num: params[:shift_num], machine_name: params[:machine]) 
    rec_oee = OeeCalculation.where(date: params[:date], shift_num: params[:shift_num], machine_name: params[:machine])
    quality_data =  ProductionPart.where(date: params[:date], shift_num: params[:shift_num], machine_name: params[:machine])
    
    if availability_data.present?
      duration = availability_data.first.duration
      run_time = availability_data.first.run_time
      availability = (run_time)/(duration).to_f
    else
      duration = 0
      run_time = 0
      availability = 0
    end


    if quality_data.present?
      total_count = quality_data.pluck(:productresult).sum
      good_count = quality_data.where(accept_count: 1).pluck(:productresult).sum
      reject_count = quality_data.where(reject_count: 1).pluck(:productresult).sum     
      quality = (good_count)/(total_count).to_f
    else
      total_count = 0
      good_count = 0
      reject_count = 0
      quality = 0
    end


    if rec_oee.present?
        target = rec_oee.target
      else
        target = 0
      end
      res_run_rate = []
      rec_oee.each do |tar_rec| 
        tar_rec_pg_no = tar_rec.first["program_number"]
        tar_rec_run_rate = tar_rec.first["run_rate"]
        res_part = production.where(program_number: tar_rec_pg_no).pluck(:productresult).sum
        res_run_rate << res_part * tar_rec_run_rate
      end

      if rec_oee.present?
        if run_time == 0
          perfomance = 0
        else
          perfomance = (res_run_rate.sum)/(run_time).to_f
        end
      else
        if run_time == 0
          perfomance = 0
        else
          perfomance = 1
        end
      end


   
    render json: {
      date: params[:date],
      shift_num: params[:shift_num],
      machine: params[:machine],
      availability: (availability * 100).to_f.round(0),
      perfomance: (perfomance * 100).to_f.round(0),
      quality: (quality * 100).to_f.round(0),
      actual: total_count,
      target: target,
      oee: ((availability * perfomance * quality) * 100).to_f.round(0)
    }

  end

  
  def oee_dashboard#(TV)
     date = Date.today.to_s
     data2 = []  
    shift = Shift.current_shift
 
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
     
    machines = L0Setting.pluck(:id, :L0Name)
    check_status = CurrentStatus.last#data.first["first"]
    signals = L1PoolOpened.all
    oee_records = OeeCalculation.where(date: date, shift_num: shift.shift_no)
    quality_data1 = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    machines.each do |machine|
      signal = signals.select{|j| j.L1Name == machine[1]}.first.value 
      if signal == "OPERATE"
        signal1 = "OPERATE"
      elsif signal == "DISCONNECT"
        signal1 = 'DISCONNECT'
      else
        signal1 = "STOP"
      end
      
      if (start_time..end_time).include?(check_status.up_time.localtime) 
      live_das = check_status.data.first["first"].select{|i| i["name"] == machine[1]}.first
      run_time = live_das["ori_run_time"]
      else 
      
      machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], value: "OPERATE")
      run_time = machine_logs.pluck(:timespan).sum.round
      end 
     duration =(end_time - start_time).to_i
#byebug




      if run_time == 0
       availability = 0
      else
       availability = (run_time)/(duration).to_f
      end
      t_date = Time.now
      
      quality_data = quality_data1.select{|i| i.L1Name == machine[1] && i.updatedate < t_date && i.productresult != '0' }

      if quality_data.present?
       total_count = quality_data.pluck(:productresult).map{|i| i.to_i}.sum
       good_count = quality_data.select{|i| i["accept_count"] == 1 || i["accept_count"] == nil}.pluck(:productresult).map{|i| i.to_i}.sum
       reject_count = quality_data.select{|i| i["accept_count"] == 2}.pluck(:productresult).map{|i| i.to_i}.sum
       quality = (good_count)/(total_count).to_f
      else
        total_count = 0
        good_count = 0
        reject_count = 0
        quality = 0
      end

      rec_oee = oee_records.select{|k| k[:machine_name] == machine[1]}
     
      if rec_oee.present?
        target = rec_oee[0].target
      else
        target = 0
      end

      res_run_rate = []
      rec_oee.each do |tar_rec|
        final_rec = tar_rec.idle_run_rate
        final_rec.each do |tar_rec1|
         tar_rec_pg_no = tar_rec1["program_number"]
         tar_rec_run_rate = tar_rec1["run_rate"]
         res_part = quality_data.select{|i| i["program_number"] == tar_rec_pg_no }.pluck(:productresult).sum
         res_run_rate << res_part * tar_rec_run_rate
        end
      end


      if rec_oee.present?
        if run_time == 0
          perfomance = 0
        else
          perfomance = (res_run_rate.sum)/(run_time).to_f
        end
      else
        if run_time == 0
          perfomance = 0
        else
          perfomance = 1
        end
      end

 
      data2  << {
        machine: machine[1],
        status: signal1,
        availability: (availability * 100).to_f.round(0),
        perfomance: (perfomance * 100).to_f.round(0),
        quality: (quality * 100).to_f.round(0),
        actual: total_count,
        target: target,
        oee: ((availability * perfomance * quality) * 100).to_f.round(0)
      }      

    end

    render json: data2
    
  end



  def oee_dashboard_old #(TV)

    data2 = []  
    shift = Shift.current_shift#find_by(shift_no: 4)
    
    case
    when shift.start_day == '1' && shift.end_day == '1'
     date = Date.today.to_s
    when shift.start_day == '1' && shift.end_day == '2'
      if Time.now.strftime("%p") == "AM"
        date = (Date.today - 1.day).to_s
      else
        date = Date.today.to_s
      end
    else
      date = (Date.today - 1.day).to_s
    end

    machines = L0Setting.pluck(:id, :L0Name)
    machines.each do |machine|
      signal = L1PoolOpened.where(L1Name: machine[1]).first.value
      if signal == "OPERATE"
        signal1 = "OPERATE"
      elsif signal == "DISCONNECT"
        signal1 = 'DISCONNECT'
      else
        signal1 = "STOP"
      end
          
      availability_data = Report.where(date: date, shift_num: shift.shift_no, machine_name: machine[1]) 
      
      if availability_data.present?
        duration = availability_data.first.duration
        run_time = availability_data.first.run_time
        availability = (run_time)/(duration).to_f
      else
        duration = 0
        run_time = 0
        availability = 1
      end
      
      quality_data =  ProductionPart.where(date: date, shift_num: shift.shift_no, machine_name: machine[1])
      
      if quality_data.present?
        total_count = quality_data.pluck(:productresult).sum
        good_count = quality_data.where(accept_count: 1).pluck(:productresult).sum
        reject_count = quality_data.where(reject_count: 1).pluck(:productresult).sum     
        quality = (good_count)/(total_count).to_f
      else
        total_count = 0
        good_count = 0
        reject_count = 0
        quality = 1

      end


      rec_oee = OeeCalculation.where(date: date, shift_num: shift.shift_no, machine_name: machine[1])
      if rec_oee.present?
         
       # target = rec_oee.first.target
        # target = rec_oee[0].target
        target = rec_oee[0].target
      else
        target = 0
      end
      
      res_run_rate = []
      rec_oee.each do |tar_rec| 
       # tar_rec_pg_no = tar_rec[0]["program_number"]
       # tar_rec_run_rate = tar_rec[0]["run_rate"]
       
        final_rec = tar_rec.idle_run_rate 
        final_rec.each do |tar_rec1|
         tar_rec_pg_no = tar_rec1["program_number"]
         tar_rec_run_rate = tar_rec1["run_rate"]
         res_part = quality_data.where(program_number: tar_rec_pg_no).pluck(:productresult).sum
         res_run_rate << res_part * tar_rec_run_rate
        end
      end


      if rec_oee.present?
       
        if run_time == 0
          perfomance = 0
        else
          perfomance = (res_run_rate.sum)/(run_time).to_f
        end
      else
        if run_time == 0
          perfomance = 0
        else
          perfomance = 1
        end
      end
  
      data2  << {
        machine: machine[1],
        status: signal1,
        availability: (availability * 100).to_f.round(0),
        perfomance: (perfomance * 100).to_f.round(0),
        quality: (quality * 100).to_f.round(0),
        actual: total_count,
        target: target,
        oee: ((availability * perfomance * quality) * 100).to_f.round(0)
      }

    end
    render json: data2
    
  end
  
  def kpy_dashboard
  end


  def live_production_part

   if params[:date].present? && params[:date]!= "null"
    date = params[:date].to_date.to_s
   else
    date = Date.today.to_s
   end
  #  date = params[:date].present? ? params[:date].to_date.to_s : Date.today.to_s 
    if params[:shift_num].present? && params[:shift_num] != "undefined"
     shift = Shift.find_by(shift_no: params["shift_num"])
    else
     shift = Shift.current_shift
    end
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
    
     result = ProductResultHistory.where(:L1Name.in => [params[:machine]], :enddate.gte => start_time, :updatedate.lte => end_time)
                                                                         
   
     if params[:status].present?
      if params[:status] == "nil"
       status = nil
      else
       status = params[:status].to_i
      end 
      result2 = result.select{|j| j["enddate"] < end_time && j["productresult"] != '0' && j["accept_count"] == status}
     else
      result2 = result.select{|j| j["enddate"] < end_time && j["productresult"] != '0' && j["is_verified"] != true}
     end

     page = params[:page].present? ? params[:page] : 1
     page_count = params[:per_page].present? ? params[:per_page] : 10
     result3_count = result2.count
     result3 = result2.paginate(:page => page, :per_page => page_count)

    render json: {parts: result3, count: result3_count}
     
  end

  def live_oee_tab
 
   date = params[:date].present? ? params[:date].to_date.to_s : Date.today.to_s
    if params[:shift_num].present?
     shift = Shift.find_by(shift_no: params["shift_num"])
    else
     shift = Shift.current_shift
    end
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
    
     check_status = CurrentStatus.last.data.first["first"]
     oee_records = OeeCalculation.where(date: date, shift_num: shift.shift_no, machine_name: params[:machine])
     quality_data1 = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
     live_das = check_status.select{|i| i["name"] == params[:machine]}.first
      signal1 = live_das["status"]
      run_time = live_das["ori_run_time"]
      duration =(end_time - start_time).to_i
     if run_time == 0
       availability = 0
      else
       availability = (run_time)/(duration).to_f
      end
      t_date = Time.now
      quality_data = quality_data1.select{|i| i.L1Name == params[:machine] && i.updatedate < t_date && i.productresult != '0' }
    
      if quality_data.present?
       total_count = quality_data.pluck(:productresult).map{|i| i.to_i}.sum
       good_count = quality_data.select{|i| i["accept_count"] == 1 || i["accept_count"] == nil}.pluck(:productresult).map{|i| i.to_i}.sum
       reject_count = quality_data.select{|i| i["accept_count"] == 2}.pluck(:productresult).map{|i| i.to_i}.sum
       quality = (good_count)/(total_count).to_f
      else
        total_count = 0
        good_count = 0
        reject_count = 0
        quality = 0
      end


       rec_oee = oee_records.select{|k| k[:machine_name] == params[:machine]}
      
      if rec_oee.present?
        target = rec_oee[0].target
      else
        target = 0
      end

      res_run_rate = []
      rec_oee.each do |tar_rec|
        final_rec = tar_rec.idle_run_rate
        final_rec.each do |tar_rec1|
         tar_rec_pg_no = tar_rec1["program_number"]
         tar_rec_run_rate = tar_rec1["run_rate"]
         res_part = quality_data.select{|i| i["program_number"] == tar_rec_pg_no }.pluck(:productresult).sum
         res_run_rate << res_part * tar_rec_run_rate
        end
      end


      if rec_oee.present?
        if run_time == 0
          perfomance = 0
        else
          perfomance = (res_run_rate.sum)/(run_time).to_f
        end
      else
        if run_time == 0
          perfomance = 0
        else
          perfomance = 1
        end
      end
 


      render json: {
        machine: params[:machine],
        run_time: run_time,
        actual: total_count,
        target: target,
        availability: (availability * 100).to_f.round(0),
        perfomance: (perfomance * 100).to_f.round(0),
        quality: (quality * 100).to_f.round(0),
        oee: ((availability * perfomance * quality) * 100).to_f.round(0)
      }
  end


  # GET /oee_calculations/1
  def show
    render json: @oee_calculation
  end

  # POST /oee_calculations
  def create
    
    @oee_calculation = OeeCalculation.new(oee_calculation_params)
    @oee_calculation.date = params[:date].to_time.localtime
    if @oee_calculation.save
      render json: @oee_calculation, status: :created#, location: @oee_calculation
    else
      render json: @oee_calculation.errors#, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /oee_calculations/1
  def update
    if @oee_calculation.update(oee_calculation_params)
      render json: @oee_calculation
    else
      render json: @oee_calculation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /oee_calculations/1
  def destroy
    @oee_calculation.destroy
    render json: "OK"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_oee_calculation
      @oee_calculation = OeeCalculation.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def oee_calculation_params
      params.require(:oee_calculation).permit!#(:date, :machine_name, :shift_num, :target, :actual, :availability, :perfomance, :quality, :idle_run_rate, :actual_idle_run_rate, :shift_id, :l0_setting_id)
    end
end
end
end
