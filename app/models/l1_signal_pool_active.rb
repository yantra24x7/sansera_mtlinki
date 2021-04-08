
class L1SignalPoolActive
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1Signal_Pool_Active"

   field :L1Name, type: String
   field :updatedate, type: DateTime # Date
   field :enddate, type: DateTime # Date
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: Mongoid::Boolean
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String
   
    def self.report(date, shift_no)
    puts Time.now
    data = []
    oee_data = []
    shift = Shift.find_by(shift_no:shift_no)
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
    machines = L0Setting.pluck(:L0Name)

    key_list = []
    machines.each do |jj|
    key_list << "MacroVar_750_path1_#{jj}"
    end


    key_list2 = []
    machines.each do |jj|
    key_list2 << "MacroVar_756_path1_#{jj}"
    key_list2 << "MacroVar_757_path1_#{jj}"
    end


    

    key_list1 = []
    machines.each do |jj|
    key_list1 << "MacroVar_751_path1_#{jj}"
    end
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[0]}

    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time).group_by{|kk| kk[:L1Name]}

    q_check = L1SignalPool.where(:signalname.in => key_list2, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)

    key_values = L1SignalPool.where(:signalname.in => key_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    key_value = L1SignalPoolActive.where(:signalname.in => key_list)

    key_values1 = L1SignalPool.where(:signalname.in => key_list1, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    key_value1 = L1SignalPoolActive.where(:signalname.in => key_list1)
   
    p_result1 = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)

    components = Component.all

    operators = Operator.all.pluck(:operator_spec_id, :operator_name).group_by(&:first) 
    
   # oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no)
    bls = machines - machine_log.keys
    mer_req = bls.map{|i| [i,[]]}.to_h
    machine_logs = machine_log.merge(mer_req)
 
 machine_logs.each do |key, value|   
#    if key == "VALVE-C46"
#    byebug
#    end
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
  value << L1Pool.new(updatedate: start_time, enddate: end_time, timespan: duration, value: "DISCONNECT") 
 elsif value.count == 1
  value.first[:updatedate] = start_time
  value.first[:enddate] = end_time
  value.first[:timespan] = (end_time - start_time).to_i
 else
  value.first[:updatedate] = start_time
  value.first[:timespan] = (value.first.enddate.to_time - start_time)
  value.last[:enddate] = end_time
  value.last[:timespan] = (end_time - value.last.updatedate.to_time) 
end 

#if key == "VALVE-C46"
#    byebug
#    end

#   if key == "SRB-1106"
#    aaaa = []
#    bbbb = []
#    value.each do |ss|
#    aaaa << (ss.enddate.to_time - ss.updatedate.to_time)
#    bbbb << ss.timespan
#    end
#    byebug
#   end
  

#if key == "VALVE-C85"
#    byebug
#    end




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
    idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
    alarm_time = (alarm.sum + emergency.sum)
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)

#if key == "VALVE-C46"
#    byebug
#    end

    # ====== Start ======= #
    all_data = []   
    
    lastdata = key_value.select{|h| h.L1Name == key}
    all_data = key_values.select{|g| g.L1Name == key}
#if key == "VALVE-C85"
#    byebug
#    end


    if lastdata.present?
      if lastdata.first.updatedate >= start_time
        lastdata.first[:enddate] = Time.now.utc
        all_data << lastdata.first
      end
    end
    
    operator_list = all_data.select{|i| i.value != nil}
    
    opr_list = operator_list.pluck(:value).map(&:to_i)
    operator_name = []
 #  if key == "VALVE-C85"
 #   byebug
 #   end

 
    opr_list.each do |op_li|
      if operators[op_li.to_s].present?
       operator_name << operators[op_li.to_s][0][1]
      else
       operator_name << "N/A"
      end
    end
    
#if key == "VALVE-C85"
#    byebug
#    end

    all_data1 = []
    lastdata1 = key_value1.select{|k| k.L1Name == key}
    all_data1 = key_values1.select{|l| l.L1Name == key}
#if key == "VALVE-C46"
#    byebug
#    end


    if lastdata1.present?
      if lastdata1.first.updatedate <= start_time
        lastdata1.first[:enddate] = Time.now.utc
        all_data1 << lastdata1.first
      end
    end
   
   
    time_target = []

     if all_data1.present?
      if key == 'PUMP-C86'
      # byebug
      end
       if all_data1.count == 1
        all_data1.first[:updatedate] = start_time
        all_data1.first[:enddate] = end_time
        all_data1.first[:timespan] = (end_time - start_time).to_i
       else
        all_data1.first[:updatedate] = start_time
        all_data1.first[:timespan] = (all_data1.first.enddate.to_time - start_time)
        all_data1.last[:enddate] = end_time
        all_data1.last[:timespan] = (end_time - all_data1.last.updatedate.to_time)
       end
       
        all_data1.each do |kvalue|
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
        # if key == 'VALVE-C63'
        # byebug
        # end
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

 if tr_data.present?
     tr_data.each do |data|
#if key  == "VALVE-C85"
#   byebug
#  end

        run_compinent = data[:comp_id].to_i
        sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == key}
       
         if sel_comp.present?
         tar = sel_comp.first.target
#         production_count = p_result1.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum

         production_count = p_result1.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < data[:ed_time].localtime }.pluck(:productresult).sum

         sing_part_time = shift.actual_hour/tar
         run_hr = data[:ed_time].to_i - data[:st_time].to_i
         target = run_hr/sing_part_time
         if target.to_f == 0.0
         effe = 0
         else 
         effe = production_count.to_f/target.to_f
         end
         effi = (effe * 100).to_i
        # compiled_component << {machine: key[0], efficiency: effi}
     #    if key  == "VALVE-C85"
  # byebug
  #end


         compiled_component << {card_no: data[:comp_id].to_i, machine: key, efficiency: effi, line: key, tar: target, actual: production_count, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime}
     #    puts "#{tt} DATA"
     #    puts "NO COUNT"
       else
   
   #if key  == "VALVE-C85"
   #byebug
  #end


         production_count = p_result1.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < data[:ed_time].localtime }.pluck(:productresult).sum

         compiled_component << {card_no: data[:comp_id].to_i, machine: key, efficiency: 0, line: key,tar: 0, actual: production_count, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime}
        # compiled_component << {machine: key[0], efficiency: 0}
        end
      end
    else
     if p_result[key].present?
     ac_count = p_result[key].pluck(:productresult).map(&:to_i).sum
     else
      ac_count = 0
     end
     compiled_component << {card_no: "No Card", machine: key, efficiency: 0, line: key, tar: 0, actual: ac_count, rout_start: start_time, rout_end: end_time}
    end
#if key  == "VALVE-C85"
#   byebug
#  end
 

   if compiled_component.present?
     effi1 = compiled_component.pluck(:efficiency).sum/compiled_component.count
     tot_tar = compiled_component.pluck(:tar).sum
     act_tar = compiled_component.pluck(:actual).sum
   else
    effi1 = 0
    tot_tar = 0
    act_tar = 0
   end



    # ====== End  ======= #


#if key == 'VALVE-C46'
#byebug
#end
   
    if p_result[key].present?
     total_count = p_result[key].pluck(:productresult).map(&:to_i).sum
     part_name = p_result[key].pluck(:productname).uniq
     program_number = p_result[key].pluck(:program_number).uniq
    else
     total_count = 0
     part_name = nil
     program_number = nil
    end
#byebug
    availability = (run_time.to_f / duration.to_f)
    if tot_tar == 0
     performance = 0.0
    else
     performance = (total_count.to_f/tot_tar.to_f)
    end

#end
    qul = q_check.select{|u| u.L1Name == key}
    if qul.count == 0
     if total_count == 0
      quality = 0.0
     else
     # if tot_tar == 0
     #  quality = 0.0
     # else
     # quality = (total_count.to_f/tot_tar.to_f)
     # end
     quality = 1.0
     end
    else
     rejection_count = qul.pluck(:value).compact.sum.to_i
     if rejection_count > total_count
      quality = 0.0
     else
      accept_count = total_count - rejection_count
      if accept_count == 0
       quality = 0.0
      else
      # quality = (total_count.to_f/accept_count.to_f)
       quality = (accept_count.to_f/total_count.to_f)
      end
     end
    end

    oee = 0#((availability * performance * quality)/3.0)
  

      data << {
      date: date,
      shift_num: shift.shift_no,
      time: start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"),
      shift_id: shift.id,
      machine_name: key,
      line: mac_lists[key].first[1],
      run_time: run_time,
      idle_time: idle_time,
      alarm_time: alarm_time,
      disconnect: disconnect,
      part_count: total_count,
      part_name: part_name,
      program_number: program_number,
      component_id: tr_data.pluck(:comp_id),
      duration: duration,
      utilisation: utilisation,
      target: tot_tar,
      actual: total_count,
      efficiency: effi1,
      availability: availability,
      perfomance: performance,
      quality: quality,
      oee: oee,
      operator: operator_name,
      operator_id: opr_list,
      route_card_report: compiled_component
    }
    
  end


   data.each do |data1|
 
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        
        report = Report.create(time: data1[:time], date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee], target: data1[:target], actual: data1[:actual], efficiency: data1[:efficiency], line: data1[:line], component_id: data1[:component_id], operator: data1[:operator], operator_id: data1[:operator_id], route_card_report: data1[:route_card_report])
       else 
        report = Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).last
        
        report.update(time: data1[:time], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee],target: data1[:target], actual: data1[:actual],efficiency: data1[:efficiency], line: data1[:line], component_id: data1[:component_id], operator: data1[:operator], operator_id: data1[:operator_id], route_card_report: data1[:route_card_report])   
      end
    end
  end





def self.current_status#(date, shift_no)
    puts Time.now
    date = Date.today.to_s
    data2 = []
    oee_data = []
    shift = Shift.current_shift
   # shift = Shift.find_by(shift_no:shift_no)
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
    
    machines = L0Setting.pluck(:L0Name)
    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
   # p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time).group_by{|kk| kk[:L1Name]}
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
  value << L1Pool.new(updatedate: start_time, enddate: end_time, timespan: duration, value: "DISCONNECT")
 elsif value.count == 1
  value.first[:updatedate] = start_time
  value.first[:enddate] = end_time
  value.first[:timespan] = (end_time - start_time).to_i
 else
  value.first[:updatedate] = start_time
  value.first[:timespan] = (value.first.enddate.to_time - start_time)
  value.last[:enddate] = end_time
  value.last[:timespan] = (end_time - value.last.updatedate.to_time)
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
      dd = CurrentStatus.first

        dd.update(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third, time: Time.now.localtime}])

    else
      CurrentStatus.create(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third , time: Time.now.localtime}])
    end

end




end
