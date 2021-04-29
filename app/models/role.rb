class Role
  include Mongoid::Document
  field :role_name, type: String
  validates :role_name, uniqueness: true  

  def self.dashboard
    all_data = []
    date = Date.today.to_s
   # date = "23-03-2021".to_date.to_s
    shift = Shift.current_shift
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



    duration = (end_time - start_time).to_i
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[0]}
    machines = mac_lists.keys

    macro_list = []
    machines.each do |jj|
     # macro_list << "MacroVar_750_path1_#{jj}" #Operator Id
      macro_list << "MacroVar_751_path1_#{jj}" #Route Card
    #  macro_list << "MacroVar_752_path1_#{jj}" #Operation Number
    #  macro_list << "MacroVar_753_path1_#{jj}" #Setting
      macro_list << "MacroVar_755_path1_#{jj}" #Idle Reason
      macro_list << "MacroVar_756_path1_#{jj}" #Rejection
      macro_list << "MacroVar_757_path1_#{jj}" #Rework
    end

    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    signal_logs = L1SignalPool.where(:signalname.in => macro_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    signal_log = L1SignalPoolActive.where(:signalname.in => macro_list)
    
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
       value << L1Pool.new(updatedate: start_time, enddate: Time.now.localtime, timespan: (Time.now.localtime - start_time), default: (Time.now.localtime - start_time),  value: "DISCONNECT")
     elsif value.count == 1
       value.first[:updatedate] = start_time
       value.first[:enddate] = end_time
#       value.first[:default] = (Time.now.localtime - start_time).to_i
       value.first[:timespan] = (Time.now.localtime - start_time).to_i
     else
       value.first[:updatedate] = start_time
       value.first[:timespan] = (value.first.enddate.to_time - start_time)
#       value.first[:default] = (value.first.enddate.to_time - start_time)
       value.last[:enddate] = Time.now.localtime
       value.last[:timespan] = (Time.now.localtime - value.last.updatedate.to_time)
#       value.last[:default] = (Time.now.localtime - value.last.updatedate.to_time)
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
    #if key == 'PUMP-C58'
    
    #end
     total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
     bls = duration - total_running_time
     run_time = operate.sum
     idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
     alarm_time = (alarm.sum + emergency.sum)
     disconnect = (disconnect.sum + bls)
     utilisation = ((run_time*100) / duration)
     total_count_shift = p_result.select{|d| d.L1Name == key && d.productresult != 0 && d.productresult != nil}.pluck(:productresult).sum
   
     tot_idle = idle_time + alarm_time
     tot_idle_time = ((tot_idle*100)/duration)
     dis_or_bls = ((disconnect*100)/duration)
     


     tot_rejection = signal_logs.select{|o| o.enddate > start_time && o.updatedate < end_time && o.signalname == "MacroVar_756_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
     tot_rework =  signal_logs.select{|w| w.enddate > start_time && w.updatedate < end_time && w.signalname == "MacroVar_757_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i != 0}.sum
     






     route_card_data = []
     route_logs = signal_logs.select{|g| g.L1Name == key && g.signalname == "MacroVar_751_path1_#{key}"}
     route_log = signal_log.select{|f| f.L1Name == key && f.signalname == "MacroVar_751_path1_#{key}"}
     # ----- Idle Reason ---- #
     idle_reason_data = []
     idle_logs = signal_logs.select{|g| g.L1Name == key && g.signalname == "MacroVar_755_path1_#{key}"}
     
     if route_log.present?
      if [start_time..end_time].include?(route_log.first.updatedate) || route_log.first.updatedate <= start_time
        route_log.first[:enddate] = end_time.utc
        route_logs << route_log.first
      end
     end


     time_wise_route_card = []

     if route_logs.present?
      if route_logs.count == 1
        route_logs.first[:updatedate] = start_time
        route_logs.first[:enddate] = end_time
        route_logs.first[:timespan] = (end_time - start_time).to_i
      else
        route_logs.first[:updatedate] = start_time
        route_logs.first[:timespan] = (route_logs.first.enddate.to_time - start_time)
        route_logs.last[:enddate] = end_time
        route_logs.last[:timespan] = (end_time - route_logs.last.updatedate.to_time)
      end
       route_logs.each do |kvalue|
        if time_wise_route_card.count == 0
          if  kvalue.value != nil
          time_wise_route_card << kvalue
          end
        else
          if time_wise_route_card[-1].value == kvalue.value || kvalue.value == nil || time_wise_route_card[-1].value == nil || kvalue.value == 0.0
            time_wise_route_card << kvalue
          else
            time_wise_route_card << "##"
            time_wise_route_card << kvalue
          end
        end
      end
     end

     time_wise_route_list = []
     if time_wise_route_card.present?
       cumulate_data = time_wise_route_card.split("##")
       cumulate_data.each do |kk|
         comp_id = kk.pluck(:value).compact.uniq.first
         st_time = kk.first.updatedate
         en_time = kk.last.enddate
         time_wise_route_list << {comp_id: comp_id, st_time:st_time, ed_time: en_time}
        end
     end
     if time_wise_route_list.present?
       time_wise_route_list.each do |data|
         production_result  = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < data[:ed_time].localtime && sel.productresult != 0}

#         opr_list = signal_logs.select{|o| o.enddate > data[:st_time].localtime && o.updatedate < data[:ed_time].localtime && o.signalname == "MacroVar_750_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.map(&:to_i)

 #       operator_name = []
 #       opr_list.each do |op_li|
 #        if operators[op_li.to_s].present?
 #          operator_name << operators[op_li.to_s][0][1]
 #        else
 #          operator_name << "N/A"
 #        end
 #       end

         if production_result.present?
           actual_produced =  production_result.pluck(:productresult).sum
           product_start_time = production_result.first.updatedate.localtime
           product_end_time = production_result.first.enddate.localtime
           id_time_duration = []
           if idle_logs.present?
             ac = idle_logs.reject{|kk| kk.value == 0}
             ac_data = ac.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime}
             if ac_data.present?
               unless ac_data.first.updatedate > data[:st_time].localtime
                ac_data.first.updatedate = data[:st_time]
               end
               if ac_data.first.enddate > data[:ed_time].localtime
                ac_data.first.enddate = data[:ed_time]
               end
               ac_data.each do |dd|
                id_time_duration << (dd.enddate.to_i - dd.updatedate.to_i).to_f
               end
             end
           else
           end
           if start_time <= product_start_time
            cycle_time = value.select{|jj| jj.enddate > product_start_time && jj.updatedate < product_end_time  && jj.value == "OPERATE"}.pluck(:timespan).sum
           else
            cycles = []
            cycles << L1Pool.where(:enddate.gte => product_start_time, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
            cycles << L1Pool.where(:enddate.gte => product_start_time+1, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
            cyc_time = cycles.reject{|k| k==0}
            if cyc_time.empty?
             cycle_time = 0
            else
             cycle_time = cyc_time.min
            end
           end
           run_hr = data[:ed_time].to_i - data[:st_time].to_i
           if cycle_time == 0
            target = 0.0
            effe = 0.0
           else
            running_hour = (run_hr - (id_time_duration.sum))
            target = (running_hour/cycle_time).to_i
            if target.to_f == 0.0
              effe = 0
            else
              effe = (actual_produced.to_f/target.to_f)
            end
           end
            rejection = signal_logs.select{|o| o.enddate > data[:st_time].localtime && o.updatedate < data[:ed_time].localtime && o.signalname == "MacroVar_756_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
           rework =  signal_logs.select{|w| w.enddate > data[:st_time].localtime && w.updatedate < data[:ed_time].localtime && w.signalname == "MacroVar_757_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i != 0}.sum
  #         oper_id = signal_logs.select{|q| q.enddate > data[:st_time].localtime && q.updatedate < data[:ed_time].localtime && q.signalname == "MacroVar_752_path1_#{key}"}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}


           float_value = data[:comp_id]%1
           if data[:comp_id] == 0
             mode = "No Entry"
           elsif float_value == 0
             mode = "Production"
           else
             mode = "Setting"
           end

           route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: effe*100, line: mac_lists[key].first[1], tar: target, actual: actual_produced, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime, rejection: rejection, rework: rework, opeation_no: [], operator_id: [], operator_name: []}

         else
          float_value = data[:comp_id]%1
          if data[:comp_id] == 0
           mode = "No Entry"
          elsif float_value == 0
           mode = "Production"
          else
           mode = "Setting"
          end

          route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: 0, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime, rejection: 0, rework: 0, opeation_no: [], operator_id: [], operator_name:[]}
         end
       end
     else
      route_card_data << {mode: "No Entry", card_no: "No Card", machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: total_count_shift, rout_start: start_time, rout_end: end_time, rejection: tot_rejection, rework: tot_rework, opeation_no: [], operator_id: [], operator_name: []}
     end

     total_route_entry = route_card_data.select{|u| u[:mode] == "Production" && u[:efficiency] != 0}
     if total_route_entry.present?
     m_tar =  total_route_entry.pluck(:tar).sum
     total_efficiency = total_route_entry.pluck(:efficiency).sum
     over_all_efficiency = (total_efficiency.to_f/total_route_entry.count)
     else
     m_tar = 0
     over_all_efficiency = 0
     end

     all_data << {
                  machine: key,
                  line: mac_lists[key].first[1],
                  tar: m_tar,
                  actual: total_count_shift,
                  efficiency: over_all_efficiency.to_i,
                  run: utilisation.to_i,
                  idle: tot_idle_time.to_i,
                  dis: dis_or_bls.to_i,
                  run_time: run_time,
                  idle_time: tot_idle,
                  discon_time: disconnect
                 }      

   end
    if CurrentStatus.present?
    CurrentStatus.last.update(r_data: all_data, r_up_time: Time.now)
    else
     CurrentStatus.create(r_data: all_data, r_up_time: Time.now)
    end
   puts Time.now
  end
 
















































   def self.part_update_live
  	date = Date.today.strftime("%d-%m-%Y")  
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
      start_time = (date+" "+shift.start_time).to_time+1.day
      end_time = (date+" "+shift.end_time).to_time+1.day
    end
    machines = L0Setting.pluck(:id, :L0Name)
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    
    machines.each do |machine|
      prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog).reverse
      pg_list = []
      prog.each_with_index do |ii, j|
		    case 
		     when ii == prog[0]
		      pg_list << ii
		     when ii == prog[-1]
		       pg_list << ii
		     when pg_list[-1][-1] != ii[-1]
                       pg_list << prog[j-1]
		       pg_list << "##"
		       pg_list << ii
		    end
   		end
   		prog_final_list = pg_list.split("##")
   		m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}.pluck(:id)
    	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
    	prog_final_list.each do |jj|
    		unless jj == [] 
   				ppg_no = jj.first[2].split("/").last
   				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
   				up_data.update_all(program_number: ppg_no)
   			end
   		end
   		puts machine[1]
    end
     ProductTime.last.update(last_time: p_result.last.updatedate)
  end


  def self.part_update(date, shift_no)
	#date = Date.today.strftime("%d-%m-%Y")  
  #shift = Shift.current_shift
  shift = Shift.find_by(shift_no:shift_no)
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
    start_time = (date+" "+shift.start_time).to_time+1.day
    end_time = (date+" "+shift.end_time).to_time+1.day
  end
  machines = L0Setting.pluck(:id, :L0Name)
  p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
  machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog).reverse
    
    pg_list = []
    prog.each_with_index do |ii, j|

	    case 
	     when ii == prog[0]
	      pg_list << ii
	     when ii == prog[-1]
	       pg_list << ii
	     when pg_list[-1][-1] != ii[-1]
	       pg_list << prog[j-1]
               pg_list << "##"
	       pg_list << ii
	    end
 		end
 		prog_final_list = pg_list.split("##")
 		m_p_result = p_result.select{|m| m.enddate < end_time &&  m.L1Name == machine[1] && m.productresult != '0'}.pluck(:id)
  	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
       
       prog_final_list.each do |jj|
  		unless jj == [] 
 				ppg_no = jj.first[2].split("/").last
 				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
 				up_data.update_all(program_number: ppg_no)
 			end
 		end
 		puts machine[1]
 		puts final_p_res.count
  end
  end

  def self.part_update_with_time(start_time, end_time)
  	machines = L0Setting.pluck(:id, :L0Name)
  	p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
  	machines.each do |machine|
        prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog).reverse
	    pg_list = []
	    prog.each_with_index do |ii, j|
		    case 
		     when ii == prog[0]
		      pg_list << ii
		     when ii == prog[-1]
		       pg_list << ii
		     when pg_list[-1][-1] != ii[-1]
		       pg_list << prog[j-1]
                       pg_list << "##"
		       pg_list << ii
		    end
	 		end
	 		prog_final_list = pg_list.split("##")
	 		m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}.pluck(:id)
	  	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
	  	prog_final_list.each do |jj|
	  		unless jj == [] 
	 				ppg_no = jj.first[2].split("/").last
	 				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
	 				up_data.update_all(program_number: ppg_no)
	 			end
	 		end
	 		puts machine[1]
	 		puts final_p_res.count
	  end
  end
  

def self.part_update_last_time
  last_data = ProductTime.last
  if last_data.present?
   time = last_data.last_time
  else
    ProductTime.create(last_time: Time.now)
    time = Time.now
  end
    machines = L0Setting.pluck(:id, :L0Name)
    p_result = ProductResultHistory.where(:enddate.gte => time)
    machines.each do |machine|
      prog = ProgramHistory.where(:enddate.gte => time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog).reverse
      pg_list = []
      prog.each_with_index do |ii, j|
                    case
                     when ii == prog[0]
                      pg_list << ii
                     when ii == prog[-1]
                       pg_list << ii
                     when pg_list[-1][-1] != ii[-1]
                       pg_list << prog[j-1]
                       pg_list << "##"
                       pg_list << ii
                    end
                end
                prog_final_list = pg_list.split("##")
                m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.productresult != '0'}.pluck(:id)
                final_p_res = ProductResultHistory.where(:id.in => m_p_result)
                                prog_final_list = pg_list.split("##")
                m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.productresult != '0'}.pluck(:id)
        final_p_res = ProductResultHistory.where(:id.in => m_p_result)
        prog_final_list.each do |jj|
                unless jj == []
                                ppg_no = jj.first[2].split("/").last
                                up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
                                up_data.update_all(program_number: ppg_no)
                        end
                end
                puts machine[1]
    end  
  ProductTime.last.update(last_time: p_result.last.updatedate)
end

end
