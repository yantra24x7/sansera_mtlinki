
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
    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time).group_by{|kk| kk[:L1Name]}
   
   # oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no)
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

   if key == "SRB-1106"
    aaaa = []
    bbbb = []
    value.each do |ss|
    aaaa << (ss.enddate.to_time - ss.updatedate.to_time)
    bbbb << ss.timespan
    end
#    byebug
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
    idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
    alarm_time = (alarm.sum + emergency.sum)
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)

   
    if p_result[key].present?
     total_count = p_result[key].pluck(:productresult).map(&:to_i).sum
     part_name = p_result[key].pluck(:productname).uniq
     program_number = p_result[key].pluck(:program_number).uniq
    else
     total_count = 0
     part_name = nil
     program_number = nil
    end
#    production = p_result["SRB-1106"].pluck(:productresult).map(&:to_i).sum
#    p_part_data = []
#    oee_data_result = []
#    rec_oee = oee_data.select{|kk| kk.machine_name == key}
#    if rec_oee.present?
#       res_run_rate = []
#       rec_oee.each do |tar_rec|
#        final_rec = tar_rec.idle_run_rate
#        final_rec.each do |tar_rec1|
#         tar_rec_pg_no = tar_rec1["program_number"]
#         tar_rec_run_rate = tar_rec1["run_rate"]
#         res_part = p_result.where(program_number: tar_rec_pg_no).pluck(:productresult).sum
#         res_run_rate << res_part * tar_rec_run_rate
#        end
#      end
#      target = rec_oee[0].target
#      if run_time == 0
#        perfomance = 0.0
#      else
#        perfomance = (res_run_rate.sum)/(run_time).to_f
#      end
#    else
#      target = 0
#      if run_time == 0
#        perfomance = 0.0
#      else
#        perfomance = 1.0
#      end
#    end

#    total_pro_data = production.select{|i| i.L1Name == key && i.productresult != '0' }
#    if total_pro_data.present?
#    total_count = total_pro_data.pluck(:productresult).map(&:to_i).sum
#    good_count =  production.select{|pp| pp.accept_count == nil || pp.accept_count == 1}.pluck(:productresult).map(&:to_i).sum
#    reject_count = production.select{|pp| pp.accept_count == 2}.pluck(:productresult).map(&:to_i).sum
#    quality = (good_count)/(total_count).to_f
#    else
#    total_count = 0
#    good_count = 0
#    reject_count = 0
#    quality = 0
#    end

#    availability = (utilisation)/(100).to_f
#    oee = (availability*perfomance*quality)*100


#   end

   
 #   machines.each do |machine|
 #     production = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}  
 #     p_part_data = []
 #     oee_data_result = []
  

      data << {
      date: date,
      shift_num: shift.shift_no,
      shift_id: shift.id,
      machine_name: key,
      run_time: run_time,
      idle_time: idle_time,
      alarm_time: alarm_time,
      disconnect: disconnect,
      part_count: total_count,
      part_name: part_name,
      program_number: program_number,
      duration: duration,
      utilisation: utilisation,
      target: nil,
      actual: total_count,
      availability: nil,
      perfomance: nil,
      quality: nil,
      oee: nil
    }
    
  end


   data.each do |data1|
  
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        
        report = Report.create(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee], target: data1[:target], actual: data1[:actual])
      else  
        report = Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).last
        report.update(run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee],target: data1[:target], actual: data1[:actual])   
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
