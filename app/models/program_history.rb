class ProgramHistory
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "Program_History"

   field :L1Name, type: String
   field :L0Name, type: String
   field :path, type: String
   field :mainprogflg, type: Boolean
   field :mainprog, type: String
   field :runningprog, type: String
   field :timespan, type: Integer
   field :updatedate, type: DateTime
   field :enddate, type: DateTime
  
   

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

    #machines = L0Setting.where(L0Name:'SDD-1104').pluck(:id,:L0Name)
    machines = L0Setting.pluck(:id,:L0Name)
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    byebug
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no)
   
    machines.each do |machine|
      production = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}  
      p_part_data = []
      oee_data_result = []
     
      other_data = aa.select{|ii| ii.L1Name == machine[1]}
      machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == machine[1]}  
        
      other_data.each do |torcher_data|
      case 
      when torcher_data.updatedate.localtime < start_time.localtime && torcher_data.enddate.localtime > end_time.localtime
        time_span = end_time - start_time
        machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: end_time, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
      when torcher_data.updatedate.localtime < start_time.localtime
        time_span = torcher_data.enddate.localtime - start_time
        machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: torcher_data.enddate, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
      when torcher_data.enddate.localtime > end_time.localtime   
        time_span = end_time - torcher_data.updatedate.localtime
        machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: torcher_data.updatedate, enddate: end_time, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
      end
      end    
      
    final_data = machine_log.sort_by &:updatedate 
    duration = (end_time - start_time).to_i
    operate = []
    manual = []
    disconnect = []
    alarm = []
    emergency = []
    stop = []
    suspend = []
    warmup = []

    final_data.each do  |dat|
    case 
      when dat.value == "OPERATE"
        operate << dat.timespan
      when dat.value == "MANUAL"
        manual << dat.timespan
      when dat.value == "DISCONNECT"
        disconnect << dat.timespan
      when dat.value == "ALARM"
        alarm << dat.timespan
      when dat.value == "EMERGENCY"
        emergency << dat.timespan
      when dat.value == "STOP"
        stop << dat.timespan
      when dat.value == "SUSPEND"
        suspend << dat.timespan
      when dat.value == "WARMUP"
        warmup << dat.timespan
      end
    end
    
    total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
    bls = duration - total_running_time    
    run_time = operate.sum
    idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
    alarm_time = (alarm.sum + emergency.sum)  
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)


    rec_oee = oee_data.select{|kk| kk.machine_name == machine[1]}
    
    if rec_oee.present?
       res_run_rate = []
       rec_oee.each do |tar_rec| 
        final_rec = tar_rec.idle_run_rate 
        final_rec.each do |tar_rec1|
         tar_rec_pg_no = tar_rec1["program_number"]
         tar_rec_run_rate = tar_rec1["run_rate"]
         res_part = p_result.where(program_number: tar_rec_pg_no).pluck(:productresult).sum
         res_run_rate << res_part * tar_rec_run_rate
        end
      end

      target = rec_oee[0].target
      if run_time == 0
        perfomance = 0.0
      else
        perfomance = (res_run_rate.sum)/(run_time).to_f
      end
    else
      target = 0
      if run_time == 0
        perfomance = 0.0
      else
        perfomance = 1.0
      end
    end 
  # byebug    
    total_pro_data = production.select{|i| i.L1Name == machine[1] && i.productresult != '0' }
    if total_pro_data.present?
    total_count = total_pro_data.pluck(:productresult).map(&:to_i).sum
    good_count =  production.select{|pp| pp.accept_count == nil || pp.accept_count == 1}.pluck(:productresult).map(&:to_i).sum
    reject_count = production.select{|pp| pp.accept_count == 2}.pluck(:productresult).map(&:to_i).sum
    quality = (good_count)/(total_count).to_f 
    else
    total_count = 0
    good_count = 0
    reject_count = 0
    quality = 0
    end

    availability = (utilisation)/(100).to_f
    oee = (availability*perfomance*quality)*100   
      data << {
      date: date,
      shift_num: shift.shift_no,
      shift_id: shift.id,
      machine_name: machine[1],
      run_time: run_time,
      idle_time: idle_time,
      alarm_time: alarm_time,
      disconnect: disconnect,
      part_count: total_count,
      part_name: production.pluck(:productname).uniq,
      program_number: production.pluck(:program_number).uniq,
      duration: duration,
      utilisation: utilisation,
      target: target,
      actual: total_count,
      availability: availability,
      perfomance: perfomance,
      quality: quality,
      oee: oee
    }
    puts machine[1]
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








end
