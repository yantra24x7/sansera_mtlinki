module Api
  module V1
    class ReportsController < ApplicationController
     before_action :set_report, only: [:re_report]    
     def module_filter
      mac_list = L0Setting.pluck(:L0Name, :L0EnName)
      mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[1]}.keys
      render json: mac_lists
      
     end

     def report_filter
      mac_list = L0Setting.pluck(:L0Name, :L0EnName)
      unless params[:line] == 'all'
      mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[1]}
      if mac_lists.present?
       if mac_lists[params[:line]].present?
        data = mac_lists[params[:line]].map{|i| i[0]}
        render json: data
       else
        render json: "No Machine Found"
       end
      else
        render json: "No Machine Found"
      end
      else
       render json: mac_list.map{|i| i[0]}
      end
     end  
 

     def operator_filter
      st_time = params[:from_date].present? ? params[:from_date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')
      en_time =   params[:from_date].present? ? params[:from_date].split('-')[1] : (Date.today - 1).strftime('%m/%d/%Y')

      start_time = Date.strptime(st_time, '%m/%d/%Y')
      end_time = Date.strptime(en_time, '%m/%d/%Y')

      range = start_time.to_time..end_time.to_time
      # machines = params[:machine_name].present? ? [params[:machine_name]] : L0Setting.pluck(:L0Name)
      machines = params[:machine_name] == "all"  ? L0Setting.pluck(:L0Name) : [params[:machine_name]]
      # shifts = params[:shift_num].present? ? [params[:shift_num]] : Shift.pluck(:shift_no)
      shifts = params[:shift_num] == "all" ? Shift.pluck(:shift_no) : [params[:shift_num]]

      result = Report.where(date:range, :shift_num.in =>shifts, :machine_name.in => machines)
      op_ids = result.pluck(:operator_id).sum.uniq
      
      operator_lists = Operator.where(:operator_spec_id.in => op_ids).pluck(:operator_spec_id, :operator_name)
      render json: operator_lists
     end 
     
     def re_route_card
      report = Report.find(params[:id])
      if report.present?
       render json: report#.route_card_report
      else
       render json: "Record Not Fount"
      end
     end
     
     def re_report
#       byebug
#      report = Report.find(params[:id])
#       byebug
#       if report.present?
       @report.update(report_params)
#       render json: report
#      else
#       render json: "Record Not Fount"
#      end
      render json: @report
     end

     def machine_list
      machine = L0Setting.pluck(:L0Name)
      render json: machine
     end
     def idle_report
#byebug       
       machine = params[:machine]#Machine.where(id: params[:machine_id]).ids
       st_time = params[:date].present? ? params[:date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')
       date = Date.strptime(st_time, '%m/%d/%Y')
  
      # date = params[:date].to_date.strftime("%Y-%m-%d")
       shift = params[:shift]#Shifttransaction.where(id:params[:shift_id]).pluck(:shift_no)
#       byebug
#       idle_report = IdleReasonActive.where(date:  date.to_time.strftime("%m-%d-%Y"), shift_no: shift, machine_name: machine)
        idle_report = IdleReasonActive.where(date:  date, shift_no: shift, machine_name: machine) 
      render json: idle_report
  #  data = CncHourReport.where(date: date, machine_id: machine, shift_no: shift)

     end     
     def overall_chart
      
      st_time = params[:from_date].present? ? params[:from_date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')  
      en_time =   params[:from_date].present? ? params[:from_date].split('-')[1] : (Date.today - 1).strftime('%m/%d/%Y') 
      
      start_time = Date.strptime(st_time, '%m/%d/%Y')
      end_time = Date.strptime(en_time, '%m/%d/%Y')
       
      range = start_time.to_time..end_time.to_time
      # machines = params[:machine_name].present? ? [params[:machine_name]] : L0Setting.pluck(:L0Name)
      machines = params[:machine_name] == "all"  ? L0Setting.pluck(:L0Name) : [params[:machine_name]]
      # shifts = params[:shift_num].present? ? [params[:shift_num]] : Shift.pluck(:shift_no)
      shifts = params[:shift_num] == "all" ? Shift.pluck(:shift_no) : [params[:shift_num]]
      if params[:select_type] == "Operatorwise" && params[:operator_id].present?
        results = Report.where(date:range, :shift_num.in =>shifts, :machine_name.in => machines)
        res_id = results.select{|i| i.operator_id.include?(params[:operator_id].to_i)}.pluck(:id)
        
        result = Report.where(:id.in=> res_id)
      else     
      result = Report.where(date:range, :shift_num.in =>shifts, :machine_name.in => machines)
      end
      render json: result
     end


     def shift_eff_report
     end



     def compare_report
      
      result1 = []
      st_time = params[:from_date].present? ? params[:from_date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')  
      en_time =   params[:from_date].present? ? params[:from_date].split('-')[1] : (Date.today - 1).strftime('%m/%d/%Y') 
      
      
      start_time = Date.strptime(st_time, '%m/%d/%Y')
      end_time = Date.strptime(en_time, '%m/%d/%Y')
      #start_time = params[:from_date].present? ? params[:from_date].to_date : Date.today - 1
      #end_time = params[:to_date].present? ? params[:to_date].to_date : Date.today - 1
      
      range = start_time..end_time
      # machines = params[:machine_name].present? ? [params[:machine_name]] : L0Setting.pluck(:L0Name)
      machines = params[:machine_name]== "all" ? L0Setting.pluck(:L0Name) : [params[:machine_name]]
      # shifts = params[:shift_num].present? ? [params[:shift_num]] : Shift.pluck(:shift_no)
      shifts = params[:shift_num]== "all" ? Shift.pluck(:shift_no) : [params[:shift_num]]
      result = Report.where(date:range , :shift_num.in =>shifts, :machine_name.in => machines)
      
       result.each do |jj|
        result1 << {
          id: jj.id,
          created_at: jj.created_at,
          date: jj.date,
          deleted_at: jj.deleted_at,
          disconnect: Time.at(jj.disconnect).utc.strftime("%H:%M:%S"),
          duration: Time.at(jj.duration).utc.strftime("%H:%M:%S"),
          idle_time: Time.at(jj.idle_time).utc.strftime("%H:%M:%S"),
          machine_name: jj.machine_name,
          part_count: jj.part_count,
          part_name: jj.part_name,
          program_number: jj.program_number,
          run_time: Time.at(jj.run_time).utc.strftime("%H:%M:%S"),
          shift_id: jj.shift_id,
          shift_num: jj.shift_num,
          updated_at: jj.updated_at,
          utilisation: jj.utilisation
        }
      end

      utilisation_result = []
      run_time_result = result.pluck(:run_time).map(&:to_i).sum
      idle_time_result = result.pluck(:idle_time).map(&:to_i).sum
      disconnect_result = result.pluck(:disconnect).map(&:to_i).sum
      duration_result1 = result.pluck(:duration).map(&:to_i).sum
      #byebug
      if duration_result1 == 0
        duration_result = 1
        render json: {run_time: 0,idle_time: 0,disconnect_time: 100, table: [] }
      else
      
      duration_result = duration_result1
      overall_operate_time = run_time_result+ idle_time_result + disconnect_result
      run_time_percentage = (run_time_result*100)/(duration_result)
      idle_time_percentage = (idle_time_result*100)/(duration_result)
      disconnect_result_percentage = (disconnect_result*100)/(duration_result)
   
       cc = [run_time_percentage,idle_time_percentage,disconnect_result_percentage]
       
       hh_index = cc.index(cc.max)
       overall_percentage = cc.sum
      
     

     if overall_percentage == 100 
        run_time  = run_time_percentage
        idle_time = idle_time_percentage
        disconnect_time = disconnect_result_percentage
     elsif overall_percentage < 100
         value = 100 - overall_percentage
        if hh_index == 0
         run_time = run_time_percentage + value
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage
        elsif hh_index == 1
         run_time = run_time_percentage
         idle_time =idle_time_percentage + value
         disconnect_time =disconnect_result_percentage
        else
         run_time = run_time_percentage
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage + value
        end
     else
       value = overall_percentage - 100
        if hh_index == 0
         run_time = run_time_percentage - value
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage
        elsif hh_index == 1
         run_time = run_time_percentage
         idle_time =idle_time_percentage - value
         disconnect_time =disconnect_result_percentage
        else
         run_time = run_time_percentage
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage - value
        end
     end
      # time = {run_time: run_time,idle_time: idle_time,disconnect_time: disconnect_time}
      render json: {run_time: run_time,idle_time: idle_time,disconnect_time: disconnect_time, table: result1 }
      end
    end

     def compare_report1
      result1 = []
      #byebug
      #start_time = params[:from_date].present? ? params[:from_date].to_date : Date.today - 1
      #end_time = params[:to_date].present? ? params[:to_date].to_date : Date.today - 1
      
      st_time = params[:from_date].present? ? params[:from_date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')  
      en_time = params[:from_date].present? ? params[:from_date].split('-')[1] : (Date.today - 1).strftime('%m/%d/%Y') 
      
      start_time = Date.strptime(st_time, '%m/%d/%Y')
      end_time = Date.strptime(en_time, '%m/%d/%Y')

      range = start_time..end_time
      # machines = params[:machine_name].present? ? [params[:machine_name]] : L0Setting.pluck(:L0Name)
      machines = params[:machine_name]== "all" ? L0Setting.pluck(:L0Name) : [params[:machine_name]]

      # shifts = params[:shift_num].present? ? [params[:shift_num]] : Shift.pluck(:shift_no)
      shifts = params[:shift_num]== "all" ? Shift.pluck(:shift_no) : [params[:shift_num]]
      result = Report.where(date:range , :shift_num.in =>shifts, :machine_name.in => machines).order("idle_time DESC")
      result.each do |jj|
        result1 << {
          id: jj.id,
          created_at: jj.created_at,
          date: jj.date,
          deleted_at: jj.deleted_at,
          disconnect: Time.at(jj.disconnect).utc.strftime("%H:%M:%S"),
          duration: Time.at(jj.duration).utc.strftime("%H:%M:%S"),
          idle_time: Time.at(jj.idle_time).utc.strftime("%H:%M:%S"),
          machine_name: jj.machine_name,
          part_count: jj.part_count,
          part_name: jj.part_name,
          program_number: jj.program_number,
          run_time: Time.at(jj.run_time).utc.strftime("%H:%M:%S"),
          shift_id: jj.shift_id,
          shift_num: jj.shift_num,
          updated_at: jj.updated_at,
          utilisation: jj.utilisation
        }

      end
      
      utilisation_result = []
      run_time_result = result.pluck(:run_time).map(&:to_i).sum
      idle_time_result = result.pluck(:idle_time).map(&:to_i).sum
      disconnect_result = result.pluck(:disconnect).map(&:to_i).sum
      duration_result1 = result.pluck(:duration).map(&:to_i).sum
      
      
      if duration_result1 == 0
        duration_result = 1
        render json: {run_time: 0,idle_time: 0,disconnect_time: 100, table: [] }
      else

      duration_result = duration_result1
      overall_operate_time = run_time_result+ idle_time_result + disconnect_result
      run_time_percentage = (run_time_result*100)/(duration_result)
      idle_time_percentage = (idle_time_result*100)/(duration_result)
      disconnect_result_percentage = (disconnect_result*100)/(duration_result)
   
       cc = [run_time_percentage,idle_time_percentage,disconnect_result_percentage]
       hh_index = cc.index(cc.max)
       overall_percentage = cc.sum
      
     

     if overall_percentage == 100 
        run_time  = run_time_percentage
        idle_time = idle_time_percentage
        disconnect_time = disconnect_result_percentage
     elsif overall_percentage < 100
         value = 100 - overall_percentage
        if hh_index == 0
         run_time = run_time_percentage + value
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage
        elsif hh_index == 1
         run_time = run_time_percentage
         idle_time =idle_time_percentage + value
         disconnect_time =disconnect_result_percentage
        else
         run_time = run_time_percentage
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage + value
        end
     else
       value = overall_percentage - 100
        if hh_index == 0
         run_time = run_time_percentage - value
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage
        elsif hh_index == 1
         run_time = run_time_percentage
         idle_time =idle_time_percentage - value
         disconnect_time =disconnect_result_percentage
        else
         run_time = run_time_percentage
         idle_time =idle_time_percentage
         disconnect_time =disconnect_result_percentage - value
        end
     end
      # time = [run_time,idle_time,disconnect_time]
      
      render json: {run_time: run_time,idle_time: idle_time,disconnect_time: disconnect_time, table: result1 }
    end
    end

    def previous_shift
      
      shift = Shift.current_shift
        if Shift.first == shift
        date = (Date.today - 1.day).to_s
        shift_num = Shift.last.shift_no
      else
        date = Date.today.to_s
        shift_num = shift.shift_no.to_i - 1 
     end
     date = date.to_date.strftime('%m/%d/%Y')
        render json: {from_date: date,to_date: date,shift_num: shift_num}
   end

    def machine_count
      total_count = L0Setting.count
      shift = Shift.current_shift
      if shift.present?
       if shift.start_day == "1" && shift.end_day == "1"
       start_time = shift.start_time.to_time
       end_time = shift.end_time.to_time
     elsif shift.start_day == "1" && shift.end_day == "2"
       start_time = shift.start_time.to_time
       end_time = shift.end_time.to_time+1.day
     else
       shift_time = shift.start_time.to_time+1.day
       end_time = shift.end_time.to_time+1.day
     end
       
       if (start_time..end_time).include?(Time.now)
       shift_data = true
       else
       shift_data = false
       end
      else
       shift_data = false
      end
      
      render json: {total_count: total_count, shift_data: shift_data}
    end

    def production_part_report
      
      date = params[:from_date].to_date.to_s
     if params["shift_num"] == "all"
      start_time = (date+" "+Shift.first.start_time).to_time
      if Shift.last.end_day == '2'
       end_time = (date+" "+Shift.last.end_time).to_time+1.day
      else
       end_time = (date+" "+Shift.last.end_time).to_time
      end
     else
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
     end


      machines = params[:machine_name] == "all"  ? L0Setting.pluck(:L0Name) : [params[:machine_name]]
      result = ProductResultHistory.where(:L1Name.in => machines, :enddate.gte => start_time, :updatedate.lte => end_time)
       result2 = result.select{|j| j["productresult"] != '0' && j["is_verified"] != true}
     page = params[:page].present? ? params[:page] : 1
     page_count = params[:per_page].present? ? params[:per_page] : 10
    
     result3_count = result2.count

     if result3_count != 0
     result3 = result2.paginate(:page => page, :per_page => page_count)
     else
     result3 = []
     end
    render json: {parts: result3, count: result3_count, date: date, shift: shift.shift_no}      
    # render json: {data: result2, date: date, shift: shift.shift_no}
    end

     def idle_reason_report
      data = []
      st_time = params[:from_date].present? ? params[:from_date].split('-')[0] : (Date.today - 1).strftime('%m/%d/%Y')
      en_time =   params[:from_date].present? ? params[:from_date].split('-')[1] : (Date.today - 1).strftime('%m/%d/%Y')

      start_time = Date.strptime(st_time, '%m/%d/%Y')
      end_time = Date.strptime(en_time, '%m/%d/%Y')
      # start_time = params[:from_date].present? ? params[:from_date].to_date : Date.today - 1
      # end_time = params[:to_date].present? ? params[:to_date].to_date : Date.today - 1

      range = start_time.to_time..end_time.to_time
      # machines = params[:machine_name].present? ? [params[:machine_name]] : L0Setting.pluck(:L0Name)
      machines = params[:machine_name] == "all"  ? L0Setting.pluck(:L0Name) : [params[:machine_name]]
      # shifts = params[:shift_num].present? ? [params[:shift_num]] : Shift.pluck(:shift_no)
      shifts = params[:shift_num] == "all" ? Shift.pluck(:shift_no) : [params[:shift_num]]
      result = IdleReasonReport.where(date:range, :shift_num.in =>shifts, :machine_name.in => machines)
      tot_val = result.pluck(:duration).map(&:to_f).sum
      result.each do |dd|
        data << {
          machine_name: dd.machine_name,
          reason: dd.reason,
          shift_num: dd.shift_num,
          start_time: dd.start_time,
          end_time: dd.end_time,
          date: dd.start_time,
          duration: Time.at(dd.duration.to_i).utc.strftime("%H:%M:%S")
        }
      end
      render json: {time: Time.at(tot_val).utc.strftime("%H:%M:%S"), tabel: data}
    end





 private

        # Use callbacks to share common setup or constraints between actions.
        def set_report
          @report = Report.find(params[:id])
        end

        def report_params
          params.require(:report).permit!#(:date, :shift_num, :machine_name, :time, :line, :efficiency, :run_time, :idle_time, :alarm_time, :disconnect, :part_count, :part_name, :program_number, :duration, :utilisation, :availability, :perfomance, :quality, :oee, :target, :actual, :oee_data, :operator, :operator_id, :component_id, :edit_reason, :shift_id, :route_card_report => [])
        end




    end
  end
end
