module Api
  module V1
    class MachinesController < ApplicationController
   

    def current_idle_reason
      date = Date.today.to_s 
      module_key = params["machine"].split('-').first
      if Shift.where(module: module_key).present?
        shift = Shift.current_shift2(module_key)
      else
        shift = Shift.current_shift2("GENERAL")
      end
      case
        when shift.start_day == '1' && shift.end_day == '1'
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        when shift.start_day == '1' && shift.end_day == '2'
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time+1.day
        else
          start_time = (date+" "+shift.start_time).to_time+1.day
          end_time = (date+" "+shift.end_time).to_time+1.day
        end

       stt_time = start_time.strftime("%Y-%m-%d %H:%M:%S")#start_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")
       edd_time = end_time.strftime("%Y-%m-%d %H:%M:%S")#end_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")
      
      reason_list = IdleReason.all.pluck(:code, :reason).group_by{|kk| kk[0]} 
      idle_reason_key = []
      full_source = MachineSetting.where(group_signal: "MacroVar", L1Name: params["machine"]).pluck(:signal)
      full_source.each do |kn|
       kn.each do |val|
        if val.first[0] == "idle_reason"
          idle_reason_key << val.first[1]
        end
       end
      end
    
     return_data = []
     if idle_reason_key.present?
        idle_key = idle_reason_key.first
        url_for_root_card = "http://103.114.208.206:3000/api/v1/equipment/#{params["machine"]}/monitorings/#{idle_key}/logs?from=#{stt_time}&&to=#{edd_time}"
        resource_root_card = RestClient::Resource.new(url_for_root_card,'rabwin','yantra24x7')
        response_root_card = resource_root_card.get
        root_card_data = JSON.parse response_root_card.body
        root_card_data1 = root_card_data.select{|mm| mm["value"] != 0 && mm["value"] != nil}

        root_card_data1.each do |mm|
          if mm["end"] == nil
            return_data << {reason: reason_list[mm["value"]].first[1], start: mm["start"].to_time.localtime, end: nil, total: nil }
          else
             return_data << {reason: reason_list[mm["value"]].first[1], start: mm["start"].to_time.localtime, end:  mm["end"].to_time.localtime, total: (mm["end"].to_time.localtime - mm["start"].to_time.localtime)}
          end
        end        
     else
     end
     render json: return_data
    end

    def live_machine_detail
     date = Date.today.to_s
   #  shift = Shift.current_shift
   #  case
   #   when shift.start_day == '1' && shift.end_day == '1'
   #     start_time = (date+" "+shift.start_time).to_time
   #     end_time = (date+" "+shift.end_time).to_time
   #   when shift.start_day == '1' && shift.end_day == '2'
   #     if Time.now.strftime("%p") == "AM"
   #       start_time = (date+" "+shift.start_time).to_time-1.day
   #       end_time = (date+" "+shift.end_time).to_time
   #     else
   #       start_time = (date+" "+shift.start_time).to_time
   #       end_time = (date+" "+shift.end_time).to_time+1.day
   #     end
   #   else
   #     start_time = (date+" "+shift.start_time).to_time
   #     end_time = (date+" "+shift.end_time).to_time
   #   end
     module_key = params["machine"].split('-').first
      if Shift.where(module: module_key).present?
        shift = Shift.current_shift2(module_key)
      else
        shift = Shift.current_shift2("GENERAL")
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



      duration  = (end_time - start_time).to_i
      machine = params[:machine]
      line = params[:line]
      cur_st = CurrentStatus.last       
      operators = Operator.all  
      data = cur_st.r_data.select{|i| i[:machine] == machine}

      servo_load1 = []
      servo_load2 = []
      root_card1 = []
      op_id1 = []
      op_num1 = []
      
#      full_source = MachineSetting.where(group_signal: "MacroVar", L1Name: machine).pluck(:signal)
      
      full_sources = MachineSetting.where(:group_signal.in=> ["MacroVar", "SpindleLoad", "ServoLoad", "FeedRate"], L1Name: machine)
      full_source1 = full_sources.select{|jj| jj[:group_signal] == "MacroVar"}
      
      if full_source1.present?
       full_source = [full_source1.first.signal]
      else
       full_source = []
      end
      
      full_source.each do |kn|
        kn.each do |val|
          if val.first[0] == "route_card"
            root_card1 << val.first[1]
          elsif val.first[0] == "operation_number"
            op_num1 << val.first[1]
          elsif val.first[0] == "operator_id"
            op_id1 <<  val.first[1]
          else
          end
        end
      end

     # spindle_source_non_val = MachineSetting.where(group_signal: "SpindleLoad", L1Name: machine)
      spindle_source_non_val = full_sources.select{|jj| jj[:group_signal] == "SpindleLoad"}     

      if spindle_source_non_val.present?
        spindle_source_max_value = spindle_source_non_val.first.max
        spindle_source = spindle_source_non_val.pluck(:value)
      else
        spindle_source_max_value = 150.0
        spindle_source = [[]]
      end
   #   spindle_source = spindle_source_non_val.pluck(:value)
     
     # servo_source = MachineSetting.where(group_signal: "ServoLoad", L1Name: machine).pluck(:signal, :value)
      servo_source1 = full_sources.select{|jj| jj[:group_signal] == "ServoLoad"}
      if servo_source1.present?
       servo_source = servo_source1.pluck(:signal, :value)
      servo_source.first.first.each do |kn|
        kn.each do |val|
         case
          when val.first == "x_axis" && val.second == true
           servo_load1 << servo_source.first.last[0]    
           servo_load2 << "x_axis"
          when val.first == "y_axis" && val.second == true
           servo_load1 << servo_source.first.last[1]
           servo_load2 << "y_axis"
          when val.first == "z_axis" && val.second == true
           servo_load1 << servo_source.first.last[2]
           servo_load2 << "z_axis"
          when val.first == "a_axis" && val.second == true
           servo_load1 << servo_source.first.last[3]
           servo_load2 << "a_axis"
          when val.first == "b_axis" && val.second == true
           servo_load1 << servo_source.first.last[4]
           servo_load2 << "b_axis"
          else
           puts "Servo Not Permit "
          end
        end
      end
      else
      end
      
      feed_rate_source = full_sources.select{|jj| jj[:group_signal] == "FeedRate"}
      if feed_rate_source.present?
        feed_rate_max_value = feed_rate_source.first.max
        feed_source = feed_rate_source.pluck(:value)
      else
        feed_rate_max_value = 150.0
        feed_source = [[]]
      end

      root_card = root_card1.first
      op_id = op_id1.first
      key_list = root_card1
      servo_temp = ["ServoTemp_0_path1_#{machine}", "ServoTemp_1_path1_#{machine}", "ServoTemp_2_path1_#{machine}"]
      servo_load = servo_load1
      spendle_load = spindle_source.first

      spendle_load_log = L1SignalPool.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine, :signalname.in => spindle_source.first, :value.ne => nil)
      sp_log_over_travel = spendle_load_log.select{|kj| kj.value > spindle_source_max_value}
      sp_log_over_travel_value = sp_log_over_travel.pluck(:updatedate, :enddate, :value)
      sp_log_over_res = {count: sp_log_over_travel.count, value: sp_log_over_travel_value}
    

      feed_rate_log = L1SignalPool.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine, :signalname.in => feed_source.first, :value.ne => nil)

      feed_log_over_travel = feed_rate_log.select{|kj| kj.value > feed_rate_max_value}
      feed_log_over_travel_value = feed_log_over_travel.pluck(:updatedate, :enddate, :value)
      feed_log_over_res = {count: feed_log_over_travel.count, value: feed_log_over_travel_value}

      sig_parms = L1SignalPoolActive.where(L1Name: machine)
      sv_load = sig_parms.where(:signalname.in => servo_load)
      sp_load = sig_parms.where(:signalname.in => spendle_load)
      op_num = sig_parms.where(:signalname=> op_num1.first)

      if op_num.present?
       op_number = op_num.pluck(:value).last.to_i
      else
       op_number = 0
      end
   
      col = []
      col << root_card
      col << op_id
      macros = L1SignalPoolActive.where(:signalname.in => col)
      operator_id = macros.select{|i| i[:signalname] == op_id}
      root_card_id = macros.select{|i| i[:signalname] == root_card}
      
      if operator_id.present?
        sel_op = operators.select{|i| i[:operator_spec_id] == operator_id.first.value.to_i.to_s}
        if sel_op.present?
          operator = sel_op.first.operator_name
        else
          operator = "N/A"
        end
      else
        operator = "N/A"
      end

      if root_card_id.present?
        job = root_card_id.first.value.to_i
      else
        job = "N/A"
      end       

      res_sv_load = sv_load.pluck(:value)
      cc_count = servo_load2.count - sv_load.pluck(:value).count
       
      cc_count.times.each do |jj|
       res_sv_load << 0.0
      end
      spp1 = sp_load.pluck(:value).select{|k| k!=nil && k!= 0.0}    
      
      if spp1.empty?
       spp_load = [0.0]
      else
       spp_load = spp1
      end
      render json: {effe: data.first["efficiency"], target: data.first["tar"], actual: data.first["actual"], job: job, o_p_num: op_number,operator: operator, line: params[:line], machine: params[:machine], run_time: data.first["run"], stop: data.first["idle"], diconnect: data.first["dis"], utlization: data.first["run"], servo_load: res_sv_load, spendle_load: spp_load, sv_axis:  servo_load2 ,sp_max_val: spindle_source_max_value, sp_log_over_res: sp_log_over_res, feed_max_val: feed_rate_max_value, feed_log_over_res: feed_log_over_res }
     end





     
    def live_machine_detail1

        date = Date.today.to_s
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

        duration  = (end_time - start_time).to_i
        machine = params[:machine]
        line = params[:line]


        cur_st = CurrentStatus.last
        eff_data = cur_st.r_data.select{|kk| kk[:line] == line}
        if eff_data.present?
         over_eff = eff_data.pluck(:efficiency).sum/eff_data.count
        else
         over_eff = 0
        end
        components = Component.all
        operators = Operator.all
        p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
        
      #  sig_parms = L1SignalPool.where(L1Name: machine)
        root_card = "MacroVar_751_path1_#{machine}"
        op_id = "MacroVar_750_path1_#{machine}"
        key_list = ["MacroVar_751_path1_#{machine}"]
        servo_temp = ["ServoTemp_0_path1_#{machine}", "ServoTemp_1_path1_#{machine}", "ServoTemp_2_path1_#{machine}"]  
        servo_load = ["ServoLoad_0_path1_#{machine}", "ServoLoad_1_path1_#{machine}"]
        spendle_load = ["SpindleLoad_0_path1_#{machine}"]
        
        sig_parms = L1SignalPoolActive.where(L1Name: machine)#, signalname: servo_load)
        sv_load = sig_parms.where(:signalname.in => servo_load)
        sp_load = sig_parms.where(:signalname.in => spendle_load)
        
        col = []
        col << root_card
        col << op_id
        macros = L1SignalPoolActive.where(:signalname.in => col)
        operator_id = macros.select{|i| i[:signalname] == op_id}
        root_card_id = macros.select{|i| i[:signalname] == root_card}
 
#        byebug

        if operator_id.present?
         sel_op = operators.select{|i| i[:operator_spec_id] == operator_id.first.value.to_i.to_s}
         if sel_op.present?
          operator = sel_op.first.operator_name
         else
          operator = "N/A"
         end 
        else
          operator = "N/A"
        end
#byebug        
        if root_card_id.present?
         job = root_card_id.first.value.to_i
#         root_card_number = components.select{|i| i[:spec_id] == root_card_id.first.value.to_i}
#          if root_card_number.present?
#            job = root_card_number.first.spec_id
#          else
#            job = "N/A"
#          end
        else
          job = "N/A"
        end
    #   ===   #
    key_values = L1SignalPool.where(:signalname.in => key_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    key_value = L1SignalPoolActive.where(:signalname.in => key_list)
   
    lastdata = key_value.select{|h| h.L1Name == machine}
    all_data = key_values.select{|g| g.L1Name == machine}
 #   byebug    
    if lastdata.present?
      lastdata.first[:enddate] = Time.now.utc
      all_data << lastdata.first
    end

    
    time_target = []

      if all_data.present?
       if all_data.count == 1
        all_data.first[:updatedate] = start_time
        all_data.first[:enddate] = end_time
        all_data.first[:timespan] = (end_time - start_time).to_i
       else
        all_data.first[:updatedate] = start_time
        all_data.first[:timespan] = (all_data.first.enddate.to_time - start_time)
        all_data.last[:enddate] = end_time
        all_data.last[:timespan] = (end_time - all_data.last.updatedate.to_time)
       end

       all_data.each do |kvalue|
         if time_target.count == 0
          time_target << kvalue
         else
          if time_target[-1].value == kvalue.value || kvalue.value == nil || time_target[-1].value == nil
            time_target << kvalue
          else
            time_target << "##"
            time_target << kvalue
          end
         end
       end
      else
       time_target = []
      end

       tr_data = []
      if time_target.present?
        cumulate_data = time_target.split("##")
        cumulate_data.each do |kk|
          comp_id = kk.pluck(:value).compact.uniq.first
          st_time = kk.first.updatedate
          en_time = kk.last.enddate
          tr_data << {comp_id: comp_id, st_time:st_time, ed_time: en_time}
        end
   #   else
      end


     compiled_component = []
     tt = tr_data.count
 
     if tr_data.present?
      
          tr_data.each do |data|

        run_compinent = data[:comp_id].to_i
        sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == machine}
        if sel_comp.present?
         tar = sel_comp.first.target
         production_count = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == machine && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum
         sing_part_time = shift.actual_hour/tar
         run_hr = data[:ed_time].to_i - data[:st_time].to_i
         target = run_hr/sing_part_time
         effe = production_count.to_f/target.to_f
         effi = (effe * 100).to_i
        # compiled_component << {machine: key[0], efficiency: effi}
         compiled_component << {machine: machine, efficiency: effi, line: line, tar: target, actual: production_count}
         
         puts "NO COUNT"
       else
         
         puts "NO COUNT"
         compiled_component << {machine: machine, efficiency: 0, line: line, tar: 0, actual: 0}
        # compiled_component << {machine: key[0], efficiency: 0}
        end
      end

     else
       puts "NO DATA"
        puts "NO COUNT"
        compiled_component << {machine: machine, efficiency: 0, line: line, tar: 0, actual: 0}
     end

     tot_tar = compiled_component.pluck(:tar).sum
     act_tar = compiled_component.pluck(:actual).sum


render json: {effe: over_eff, target: tot_tar, actual: act_tar, job: job, operator: operator, line: params[:line], machine: params[:machine], run_time: params[:run_time], stop: params[:stop], diconnect: params[:disconnect], utlization: params[:utlization], servo_load: sv_load.pluck(:value), spendle_load: sp_load.pluck(:value)}

   end

  
  def line_wise_dashboard
    cur_st1 = CurrentStatus.last
    if cur_st1.present?
      m_name = cur_st1.r_data.pluck(:machine)
      col = []
      
      full_source = MachineSetting.where(group_signal: "MacroVar").pluck(:signal)
      full_source.each do |kn|
       kn.each do |val|
        if val.first[0] == "idle_reason"
          col << val.first[1]
        end
       end
      end

      status = L1PoolOpened.all
      list_of_reasons = IdleReason.all
      macros = L1SignalPoolActive.where(:signalname.in => col)
      cur_st = cur_st1.r_data.select{|li| li[:line] == params[:line]}
      
      cur_st.each do |dd|
        colr = status.select{|i| i.L1Name == dd["machine"]}
        reason = macros.select{|i| i.L1Name == dd["machine"]}
        if colr.present?
          case
          when colr.first.value == "OPERATE"
            dd[:status] = "OPERATE"
            dd[:reason] = "N/A"
          when colr.first.value == "DISCONNECT"
            dd[:status] = "DISCONNECT"
            dd[:reason] = "N/A"
          else
            dd[:status] = "STOP"
            
            if list_of_reasons.present? && reason.present?
              sel_reason = list_of_reasons.select{|kk| kk.code == reason.first.value.to_i}
              if sel_reason == []
                dd[:reason] = "N/A"
              else
                dd[:reason] = sel_reason.first.reason
              end
            else
              dd[:reason] = "N/A"
            end
          end
        else
          dd[:status] = "DISCONNECT"
          dd[:reason] = "N/A"
        end
      end
          render json: cur_st

     # end
    else
    end
  end 
  










    
    def line_wise_dashboard1
      data2 = []
        date = Date.today.to_s
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
        duration  = (end_time - start_time).to_i
        cur_st1 = CurrentStatus.last
       
        if cur_st1.present?# && cur_st1.start_time.localtime == start_time.localtime &&  cur_st1.end_time.localtime == end_time.localtime && params[:live] != "true"        
        # m_name = cur_st1.data.first["first"].pluck(:name)
#           byebug
         m_name = cur_st1.r_data.pluck(:machine)
         col = []
         m_name.each do |jj|
         col << "MacroVar_755_path1_#{jj}"
         end

         status = L1PoolOpened.all
         list_of_reasons = IdleReason.all
         macros = L1SignalPoolActive.where(:signalname.in => col)
        #  #cur_st.data.first["first"].each do |dd|
        # cur_st = cur_st1.data.first[:first].select{|li| li[:line] == params[:line]}
         cur_st = cur_st1.r_data.select{|li| li[:line] == params[:line]} 
          cur_st.each do |dd|
#byebug
           colr = status.select{|i| i.L1Name == dd["machine"]}
           reason = macros.select{|i| i.L1Name == dd["machine"]}
           if colr.present?
             case
              when colr.first.value == "OPERATE"
                dd[:status] = "OPERATE"
              when colr.first.value == "DISCONNECT"
                dd[:status] = "DISCONNECT"
              else
                dd[:status] = "STOP"

                if reason.present?
                sel_reason = list_of_reasons.select{|kk| kk.code == reason.first.value.to_i}
                  if sel_reason == []
                   dd[:reason] = "N/A"
                  else
                   dd[:reason] = sel_reason.first.reason
                  end
#                 dd[:reason] = sel_reason.first.reason
                else
                 dd[:reason] = "N/A"
                end
              end
           else
            dd[:status] = "DISCONNECT"
           end
          end
          render json: cur_st
        else

       #=======================Start=================#

    machines = L0Setting.pluck(:L0Name)
  #  mac_with_line = L0Setting.pluck(:L0Name, :line).group_by(&:first)
    mac_with_line = L0Setting.pluck(:L0Name, :L0EnName).map{|i| [i[0], i[1].split('-').first]}.group_by(&:first)
    # mac_list = L0Setting.pluck(:L0Name, :L0EnName)
   # machines = mac_list.map{|i| [i[0], i[1].split('-').first]}


    
    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
    bls = machines - machine_log.keys
    mer_req = bls.map{|i| [i,[]]}.to_h
    machine_logs = machine_log.merge(mer_req)

    machine_logs.each do |key, value|
     puts key
    operate = []
    manual = []
    disconnect = []
    alarm = []
    emergency = []
    stop = []
    suspend = []
    warmup = []

 if value.count == 0
  value << L1Pool.new(updatedate: start_time, enddate: Time.now, timespan: duration, value: "DISCONNECT")
 elsif value.count == 1
  value.first[:updatedate] = start_time
  value.first[:enddate] = Time.now
  value.first[:timespan] = (Time.now - start_time).to_i
 else
  value.first[:updatedate] = start_time
  value.first[:timespan] = (value.first.enddate.to_time - start_time)
  value.last[:enddate] = end_time
  value.last[:timespan] = (Time.now - value.last.updatedate.to_time)
end

  group_split =  value.group_by{|gg|gg[:value]}
 puts value.pluck(:timespan).sum
 group_split.each do |k,v|
   case
      when k == "OPERATE"
        operate << v.pluck(:timespan).sum
      when k == "MANUAL"
        manual << v.pluck(:timespan).sum
      when k == "DISCONNECT"
        disconnect << v.pluck(:timespan).sum
      when k == "ALARM"
        alarm << v.pluck(:timespan).sum
      when k == "EMERGENCY"
        emergency << v.pluck(:timespan).sum
      when k == "STOP"
        stop << v.pluck(:timespan).sum
      when k == "SUSPEND"
        suspend << v.pluck(:timespan).sum
      when k == "WARMUP"
        warmup << v.pluck(:timespan).sum
      end
 end

          total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
          bls = duration - total_running_time
          run_time = operate.sum
          idle_time = (manual.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum)
          disconnect = (disconnect.sum + bls)

          data2 << {
            machine: key,
            line:  mac_with_line[key].first[1],
            status: "OPERATE",
            run_time: ((run_time*100).round/duration.to_f).round(1),
            idle_time: ((idle_time*100).round/duration.to_f).round(1),
            disconnect: ((disconnect*100).round/duration.to_f).round(1)
          }

end

       first = []
      data2.each do |bb|
        hh = [bb[:run_time], bb[:idle_time], bb[:disconnect]]

        if hh.sum == 100.0
          c_run_time = bb[:run_time]
          c_idle_time = bb[:idle_time]
          c_disconnect = bb[:disconnect]
        elsif hh.sum > 100.0
          hh_index = hh.index(hh.max)
          abs_value = (hh.sum.round(1) - 100.0).round(1)
          if hh_index == 0
             c_run_time = (bb[:run_time]-abs_value).round(1)
             c_idle_time = bb[:idle_time]
             c_disconnect = bb[:disconnect]
          elsif hh_index == 1
            c_run_time = bb[:run_time]
            c_idle_time = (bb[:idle_time]-abs_value).round(1)
            c_disconnect = bb[:disconnect]
          else
            c_run_time = bb[:run_time]
            c_idle_time = bb[:idle_time]
            c_disconnect = (bb[:disconnect]-abs_value).round(1)
          end
        else
          hh_index = hh.index(hh.max)
          abs_value = (100.0 - hh.sum.round(1)).round(1)
          if hh_index == 0
             c_run_time = (bb[:run_time]+abs_value).round(1)
             c_idle_time = bb[:idle_time]
             c_disconnect = bb[:disconnect]
          elsif hh_index == 1
            c_run_time = bb[:run_time]
            c_idle_time = (bb[:idle_time]+abs_value).round(1)
            c_disconnect = bb[:disconnect]
          else
            c_run_time = bb[:run_time]
            c_idle_time = bb[:idle_time]
            c_disconnect = (bb[:disconnect]+abs_value).round(1)
          end
        end

            first << {
        utlization: c_run_time.round(0),
        name:bb[:machine],
        line:bb[:line],
       # status: bb[:status],
        run_time: c_run_time,
        stop: c_idle_time,
        disconnect: c_disconnect,
        ori_run_time: bb[:orig]
        }
      end

      first = first.sort_by!(&:zip).reverse!
      second = {
        Machine: first.pluck(:name),
        Running: first.pluck(:run_time),
        Stop: first.pluck(:stop),
        Disconnect: first.pluck(:disconnect),
        production: [10,10]
      }

#      over_all_utlize = [((first.pluck(:run_time).sum)/machines.count).round(1),((first.pluck(:stop).sum)/machines.count).round(1),((first.pluck(:disconnect).sum)  /machines.count).round(1)]

      over_all_utlize = [((first.pluck(:run_time).sum)/machine_logs.count).round(1),((first.pluck(:stop).sum)/machine_logs.count).round(1),((first.pluck(:disconnect).sum)/machine_logs.count).round(1)]


    over_all_utlize = [((first.pluck(:run_time).sum)/machine_logs.count).round(1),((first.pluck(:stop).sum)/machine_logs.count).round(1),((first.pluck(:disconnect).sum)/machine_logs.count).round(1)]

      eee = over_all_utlize.index(over_all_utlize.index.max)
      over_all_value = []
      over_all_utlize.each_with_index do |value, index|
        if over_all_utlize.sum == 100.0
          over_all_value = over_all_utlize
        elsif over_all_utlize.sum > 100.0
          if eee == index
            over_all_value << (value - 0.1).round(1)
          else
            over_all_value << value
          end
        else

     if eee == index
            over_all_value << (value + 0.1).round(1)
          else
            over_all_value << value
          end
        end
      end

      third = [
       ["Running",over_all_value[0]],
       ["Stop", over_all_value[1]],
       ["Disconnect", over_all_value[2]]
     ]
    puts "Cron End"
      puts Time.now

    if CurrentStatus.first.present?
      dd = CurrentStatus.last
        dd.update(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third, time: Time.now.localtime}])
        cur_st =  CurrentStatus.last
    else
     cur_st = CurrentStatus.create(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third , time: Time.now.localtime}])

     end

###=================END ===============##

 m_name = cur_st.data.first["first"].pluck(:name)
         col = []
         m_name.each do |jj|
         col << "MacroVar_605_path1_#{jj}"
         end
         status = L1PoolOpened.all
         list_of_reasons = IdleReason.all
         macros = L1SignalPoolActive.where(:signalname.in => col)

          cur_st.data.first["first"].each do |dd|
           colr = status.select{|i| i.L1Name == dd["name"]}
           reason = macros.select{|i| i.L1Name == dd["name"]}
           if colr.present?
             case
              when colr.first.value == "OPERATE"
                dd[:status] = "OPERATE"
              when colr.first.value == "DISCONNECT"
                dd[:status] = "DISCONNECT"
              else
                dd[:status] = "STOP"

                if reason.present?
                sel_reason = list_of_reasons.select{|kk| kk.code == reason.first.value.to_i}
                  if sel_reason == []
                   dd[:reason] = "N/A"
                  else
                   dd[:reason] = sel_reason.first.reason
                  end
                else
                 dd[:reason] = "N/A"
                end
              end
           else
            dd[:status] = "DISCONNECT"
           end
          end
          render json: cur_st.data.first

 end
        


end

    def r_get_status2
     date = Date.today.to_s
     shift = Shift.current_shift

      cur_st = CurrentStatus.all
      status = L1PoolOpened.all
      
      if cur_st.present?
       data = []
       data3 = cur_st.last.r_data
       filter_module = @current_user.module
       data3.each do |gr_data|
        if filter_module == []
        data << gr_data
        elsif filter_module.include?(gr_data['line'])
        data << gr_data
        end
       end
   #    data = data3.select{|i| i['line'] == "ELECTRICAL"}
       result_data = []
       data.group_by{|d| d[:line]}.map do |key1,value1|
       machine_status_list = []
       first = []
       time = []
       if key1 == nil
         f_name = "Line1-1"
       else
         f_name = key1
       end
       over_all_effi = value1.pluck(:efficiency).sum/value1.count
       low_perfom = value1.group_by { |x| x[:efficiency] }.min.last.first[:machine]
       log_per_tar = data.select{|i| i[:machine] == low_perfom}

       time << {run_time: log_per_tar.first[:run], stop: log_per_tar.first[:idle],  disconnect: log_per_tar.first[:dis] }
       if log_per_tar.present?
         lpt = log_per_tar.first[:tar]
         lpa = log_per_tar.first[:actual]
       else
         lpt = 0
         lpa = 0
       end
       mac_list = value1.pluck(:machine)
             mac_list.each do |m_list|
              colr = status.select{|i| i.L1Name == m_list}
               if colr.present?
                case
                when colr.first.value == "OPERATE"
                  m_status = "OPERATE"
                when colr.first.value == "DISCONNECT"
                  m_status = "DISCONNECT"
                else
                  m_status = "STOP"
                end
               else
                m_status = "DISCONNECT"
               end
              machine_status_list << {machine: m_list, value: m_status}
             end

        result_data << {Line: f_name, eff: over_all_effi, low_perf_machine: low_perfom, machine_list: mac_list, lpt: lpt, lpa: lpa, status: machine_status_list, time: time, show_time: cur_st.first.r_up_time, shift_no: shift.shift_no}


       end
       
      else
       
      end
     render json: result_data

    end


	   
    def r_get_status

     date = Date.today.to_s
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
       duration  = (end_time - start_time).to_i
       cur_st = CurrentStatus.last
       status = L1PoolOpened.all
        
     if cur_st.present?
       final_data = cur_st.r_data            
       result_data = []
       final_data.group_by{|d| d[:line]}.map do |key1,value1|
       machine_status_list = []
       first = []

       if key1 == nil
         f_name = "Line1-1"
       else
         f_name = key1
       end
 
       over_all_effi = value1.pluck(:efficiency).sum/value1.count
       low_perfom = value1.group_by { |x| x[:efficiency] }.min.last.first[:machine]
       log_per_tar = final_data.select{|i| i[:machine] == low_perfom}
 
       if log_per_tar.present?
         lpt = log_per_tar.first[:tar]
         lpa = log_per_tar.first[:actual]
       else
         lpt = 0
         lpa = 0
       end
           
       machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time, :L1Name => low_perfom).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
       
       if machine_logs.count > 0
       machine_logs.each do |key, value|
       #if value.present?

        puts key
        operate = []
        manual = []
        disconnect = []
        alarm = []
        emergency = []
        stop = []
        suspend = []
        warmup = []
     
        if value.count == 0
          value << L1Pool.new(updatedate: start_time, enddate: Time.now, timespan: duration, value: "DISCONNECT")
        elsif value.count == 1
          value.first[:updatedate] = start_time
          value.first[:enddate] = Time.now
          value.first[:timespan] = (Time.now - start_time).to_i
        else
          value.first[:updatedate] = start_time
          value.first[:timespan] = (value.first.enddate.to_time - start_time)
          value.last[:enddate] = end_time
          value.last[:timespan] = (Time.now - value.last.updatedate.to_time)
        end

       group_split =  value.group_by{|gg|gg[:value]}
       puts value.pluck(:timespan).sum
       group_split.each do |k,v|
      case
      when k == "OPERATE"
        operate << v.pluck(:timespan).sum
      when k == "MANUAL"
        manual << v.pluck(:timespan).sum
      when k == "DISCONNECT"
        disconnect << v.pluck(:timespan).sum
      when k == "ALARM"
        alarm << v.pluck(:timespan).sum
      when k == "EMERGENCY"
        emergency << v.pluck(:timespan).sum
      when k == "STOP"
        stop << v.pluck(:timespan).sum
      when k == "SUSPEND"
        suspend << v.pluck(:timespan).sum
      when k == "WARMUP"
        warmup << v.pluck(:timespan).sum
      end
      end


          total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
          bls = duration - total_running_time
          run_time = operate.sum
          idle_time = (manual.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum)
          disconnect = (disconnect.sum + bls)
     
     data2 = [{
           # machine: key,
           # status: "OPERATE",
            run_time: ((run_time*100).round/duration.to_f).round(1),
            idle_time: ((idle_time*100).round/duration.to_f).round(1),
            disconnect: ((disconnect*100).round/duration.to_f).round(1)
          }]
     # else
       
     #  data2 = [{
           # machine: key,
           # status: "OPERATE",
    #        run_time: 0,
    #        idle_time: 0,
    #        disconnect: 100
    #      }]

     # end

       
      data2.each do |bb|
        hh = [bb[:run_time], bb[:idle_time], bb[:disconnect]]

        if hh.sum == 100.0
          c_run_time = bb[:run_time]
          c_idle_time = bb[:idle_time]
          c_disconnect = bb[:disconnect]
        elsif hh.sum > 100.0
          hh_index = hh.index(hh.max)
          abs_value = (hh.sum.round(1) - 100.0).round(1)
          if hh_index == 0
             c_run_time = (bb[:run_time]-abs_value).round(1)
             c_idle_time = bb[:idle_time]
             c_disconnect = bb[:disconnect]
          elsif hh_index == 1
            c_run_time = bb[:run_time]
            c_idle_time = (bb[:idle_time]-abs_value).round(1)
            c_disconnect = bb[:disconnect]
          else
            c_run_time = bb[:run_time]
            c_idle_time = bb[:idle_time]
            c_disconnect = (bb[:disconnect]-abs_value).round(1)
          end
        else
          hh_index = hh.index(hh.max)
          abs_value = (100.0 - hh.sum.round(1)).round(1)
          if hh_index == 0
             c_run_time = (bb[:run_time]+abs_value).round(1)
             c_idle_time = bb[:idle_time]
             c_disconnect = bb[:disconnect]
          elsif hh_index == 1
            c_run_time = bb[:run_time]
            c_idle_time = (bb[:idle_time]+abs_value).round(1)
            c_disconnect = bb[:disconnect]
          else
            c_run_time = bb[:run_time]
            c_idle_time = bb[:idle_time]
            c_disconnect = (bb[:disconnect]+abs_value).round(1)
          end
        end
      
        
     first << {
        run_time: c_run_time,
        stop: c_idle_time,
        disconnect: c_disconnect,
        }
      end
        end
      else
        first << {
        run_time: 0,
        stop: 0,
        disconnect: 100
        }

      end
             mac_list = value1.pluck(:machine)
	     mac_list.each do |m_list|
	      colr = status.select{|i| i.L1Name == m_list}
	       if colr.present?
		case
		when colr.first.value == "OPERATE"
		  m_status = "OPERATE"
		when colr.first.value == "DISCONNECT"
		  m_status = "DISCONNECT"
		else
		  m_status = "STOP"
		end
	       else
		m_status = "DISCONNECT"
	       end
	      machine_status_list << {machine: m_list, value: m_status}
	     end
             
	     result_data << {Line: f_name, eff: over_all_effi, low_perf_machine: low_perfom, machine_list: mac_list, lpt: lpt, lpa: lpa, status: machine_status_list, time: first, show_time: cur_st.r_up_time, shift_no: shift.shift_no}
	    
	    end    
	     render json: result_data
	    else
	       
	    end
		    
	 end

	 
		    def index
			machines = L0Setting.all
			machine_list = machines.map{|i| [id: i[:id], L0Name: i[:L0Name], ip: i[:NetworkSetting][:IpAddress], line: i[:line]]}
			res_list = []
                        mac_settings = MachineSetting.all
                       
                        grp_value = mac_settings.group_by(&:L1Name)
                        machine_list.flatten.each do |lis|
                      # byebug
                        set_list = grp_value[lis[:L0Name]].pluck(:group_signal)
                      #  set_list = mac_settings.select{|i| i[:L1Name] == lis[:L0Name]}.pluck(:group_signal)

                        if set_list.include?("MacroVar") 
                         lis[:tag_result] = true
                        else
                         lis[:tag_result] = false
                        end
                        
                        if set_list.include?("SpindleLoad")
                         lis[:tag_result1] = true
                        else
                         lis[:tag_result1] = false
                        end
                        
                        if set_list.include?("ServoLoad")
                         lis[:tag_result2] = true
                        else
                         lis[:tag_result2] = false
                        end

                        if set_list.include?("FeedRate")
                         lis[:tag_result3] = true
                        else
                         lis[:tag_result3] = false
                        end
                         
       #                   if MachineSetting.where(group_signal: "MacroVar", L1Name: lis[:L0Name]).present?
       #                    lis[:tag_result] = true
       #                   else
       #                    lis[:tag_result] = false
       #                   end
       #                   if MachineSetting.where(group_signal: "SpindleLoad", L1Name: lis[:L0Name]).present?
       #                    lis[:tag_result1] = true
       #                   else
       #                    lis[:tag_result1] = false
       #                   end
       #                   if MachineSetting.where(group_signal: "ServoLoad", L1Name: lis[:L0Name]).present?
       #                    lis[:tag_result2] = true
       #                   else
       #                    lis[:tag_result2] = false
       #                   end
                        end
                        
                        render json: machine_list.flatten
		    end
		    def machine_update
		      
		       if L0Setting.where(L0Name: params[:machine]).present?    
			l0_setting = L0Setting.where(L0Name: params[:machine]).first.update(line: params[:line])
			render json: l0_setting
		       else
			render json: false
		       end         
		    end
		    def notification_setting
		     if NotificationSetting.where(L0Name: params[:machine]).present? 
		      data = NotificationSetting.where(L0Name: params[:machine]).first
		      data[:mean_time] = (data.mean_time/60).to_i
		      render json: {status: true, data: data}
		     else
		      render json: {status: false, data: nil}
		     end
		    end

		    def add_notification
		      if NotificationSetting.where(L0Name: params[:machine]).present?
		       render json: false
		      else
		      notifi_time = (params[:mean_time].to_i * 60).to_i
		      notification = NotificationSetting.create(L0Name: params[:machine], l0_setting_id: params[:l0_setting_id], mean_time: notifi_time, active: false)
		      notification[:mean_time] = (notification.mean_time/60).to_i
		      render json: notification
		      end
		    end

		    def update_notification
		     
		      if NotificationSetting.where(L0Name: params[:machine]).present? 
		       notifi_time = (params[:mean_time].to_i * 60).to_i
		       notification = NotificationSetting.where(L0Name: params[:machine]).first.update(mean_time: notifi_time)
	       
		       render json: notification
		      else
		      render json: false
		      end
		    end
		   
		    def change_status_notification
		     if NotificationSetting.find(params[:id]).present?
		       status =  NotificationSetting.find(params[:id]).update(active: params[:status])
		       render json: status
		     else
		       render json: false
		     end
		    end
		    def machine_status
			status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
			data = L1SignalPoolActive.where(:signalname.in => status)
			data1 = []
			data.group_by{|d| d[:L1Name]}.each do |key, value|
				ss = value.select{|a| a[:value] == true}
				data1  << {"#{key}":  ss}
			end
			render json: data1
		    end

		    







		    def single_machine_detail
			    shift = Shift.current_shift
			    date = Date.today.to_s
			case
			    when shift.start_day == 1 && shift.end_day == 1
			      start_time = (date+" "+shift.start_time).to_time
			      end_time = (date+" "+shift.end_time).to_time
			    when shift.start_day == 1 && shift.end_day == 2
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
			    
         	L1SignalPool.where(nil)		    
	    end
    end
  end
end
