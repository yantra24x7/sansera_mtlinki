class Report

  include Mongoid::Document
  include Mongoid::Timestamps
  #store_in collection: "report"
  include Mongoid::Attributes::Dynamic
  include Mongoid::Paranoia
   
  field :date, type: Date
  field :shift_num, type: Integer
  field :machine_name, type: String
  field :run_time, type: Integer
  field :idle_time, type: Integer
  field :alarm_time, type: Integer
  field :disconnect, type: Integer
  field :part_count, type: Integer
  field :part_name, type: Array
  field :program_number, type: Array
  field :duration, type: Integer
  field :utilisation, type: Integer
  field :availability, type: Float
  field :perfomance, type: Float
  field :quality, type: Float
  field :traget, type: Integer
  field :actual, type: Integer
  field :oee_data, type: Integer
  belongs_to :shift

  index({date: 1, shift_num: 1, machine_name: 1})


    def self.report#(date, shift_no)
    data = []
    date_arr = ('04-03-2020').to_date..('04-03-2020').to_date
    date_arr.each do |dat|
      
    date = dat.strftime("%d-%m-%Y")
    all_shift = Shift.where(shift_no: 1)
    all_shift.each do |shift|
      
    #shift = Shift.find_by(shift_no:shift_no)
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

    machines = L0Setting.pluck(:id, :L0Name)
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true)
    
    ll = prog.select{|hh| hh.mainprog == hh.runningprog }
      
      #m_p_result = p_result.select{|m| m.L1Name == machine && m.updatedate > start_time}
      m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time}
      p_part_data = []
      m_p_result.each do |part|
        if part.productresult != '0'

          pg_group = prog.select{|b| b.updatedate >= part.updatedate && b.enddate <= part.enddate}
          if pg_group.present?
            pg_num = pg_group.pluck(:mainprog).first
          else
            pg_num = "No PGM"
          end
          p_part_data << {date: date, shift_num: shift.shift_no, machine_name: machine[1], part_count: part.productresult_accumulate, program_number: pg_num, part_start_time: part.updatedate, part_end_time: part.enddate, cycle_time: nil, cutting_time: nil, productname: part.productname, productresult: part.productresult.to_i, productresult_accumulate: part.productresult_accumulate, timespan: part.timespan, accept_count: nil, reject_count: nil, is_verified: false, l0_setting_id: machine[0], shift_id: shift.id}
        end  
      end

      oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no)
      




      production_name = m_p_result.select{|kk| kk.productresult != 0}.pluck(:productname).uniq
     
      other_data = aa.select{|ii| ii.L1Name == machine[1]}
      
      # other_data = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
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
    idle_time = (manual.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum)
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)
     
    byebug
     
      data << {
      date: date,
      shift_num: shift.shift_no,
      shift_id: shift.id,
      machine_name: machine[1],
      run_time: run_time,
      idle_time: idle_time,
      disconnect: disconnect,
      part_count: m_p_result.pluck(:productresult).map(&:to_i).sum,
      part_name: production_name,
      program_number: ll.pluck(:mainprog).uniq,
      duration: duration,
      utilisation: utilisation,
      part: p_part_data
    }
    end
    end
    end
    
    data.each do |data1|
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        report = Report.create(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation])
        
        data1[:part].each do |single_part|
          finl_data = single_part.merge(result_id: report.id)  
          ProductionPart.create(finl_data)
        end
      
      else
       
        report = Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).last
        report.update(run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation])
        
        data1[:part].each do |single_part|
          if ProductionPart.where(machine_name: single_part[:machine_name], part_start_time: single_part[:part_start_time], part_end_time: single_part[:part_end_time]).present?
          puts "Ok"
          else
            finl_data = single_part.merge(result_id: report.id)  
            ProductionPart.create(finl_data)
          end
        end
       
      end
    end
  end


  def self.oee_calculation
    data = []
    date_arr = ('04-03-2020').to_date..('04-03-2020').to_date
    date_arr.each do |dat|
      
    date = dat.strftime("%d-%m-%Y")
    all_shift = Shift.where(shift_no: 1)

    machines = L0Setting.pluck(:id, :L0Name)
    all_shift.each do |shift|
      
    #shift = Shift.find_by(shift_no:shift_no)
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
    
    machines.each do |machine|

      oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no, l0_setting_id: machine[0])
      production = ProductionPart.where(date: date, shift_num: shift.shift_no, l0_setting_id: machine[0])
      
      rec_oee = oee_data.pluck(:idle_run_rate)
      rec_oee.flatten.each do |tar|
        total = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] }
        accept_count = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] && dd.accept_count == 1 }
        reject_count = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] && dd.reject_count == 1 }
        data << {program_number: tar["program_number"], count: total.count, accept_count: accept_count.count, reject_count: reject_count.count}
      end
      oee_data.update(actual_idle_run_rate: data, actual: data.pluck(:count).sum)

    end

  end
  end

    
  end


  def self.reason_entry
    reason_list = ["No_load", "Wire_feeding", "Setting", "Setter_unavalable", "Tally_cleaning", "Breakdown", "Tools_unavalable", "Tea_break", "Lunch_break", "Rest_room"]
    data = []
    date_arr = ('21-10-2020').to_date..('31-10-2020').to_date
   # machines = L0Setting.pluck(:id, :L0Name)
   # machines = L0Setting.where(:id.in=> ['5eba6cc55aba68b3bc24b933', '5eba6cc55aba68b3bc24b934']).pluck(:id, :L0Name)
    machines = L0Setting.pluck(:id,:L0Name)
    date_arr.each do |dat|
      
      date = dat.strftime("%d-%m-%Y")
      all_shift = Shift.all
      all_shift.each do |shift|
        
        #shift = Shift.find_by(shift_no:shift_no)
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
        
        (start_time.to_i..end_time.to_i).step(3600) do |hour|
          (hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
            #(hour.to_i+3600 <= end_time.to_i) ? (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(hour.to_i+3600).strftime("%Y-%m-%d %H:%M")) : (hour_start_time=Time.at(hour).strftime("%Y-%m-%d %H:%M"),hour_end_time=Time.at(end_time).strftime("%Y-%m-%d %H:%M"))
            unless hour_start_time[0].to_time == hour_end_time.to_time
              
            puts date

            machines.each do |machine|
                res = reason_list[rand(reason_list.length)]
                IdleReasonTransaction.create(l0_setting_id: machine[0], machine_name: machine[1], reason: res, start_time: hour_start_time[0].to_time, end_time: hour_start_time[1].to_time)
              end 
          end
        end
      end
    end
  end

  def self.idle_reason_report
  
  date = '2020-02-04' 
  shift = Shift.find_by(shift_no:2)
  machines = L0Setting.pluck(:id, :L0Name)
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

      idle_reasons = IdleReasonTransaction.where(:end_time.gte => start_time, :start_time.lte => end_time)
      status = ['MANUAL','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
      machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time, :value.in => status) 
     machines.each do |machine|
      selected_reason =  idle_reasons.select{|kk| kk.start_time >= start_time && kk.end_time <= end_time && kk.machine_name == machine[1]}
      machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == machine[1]}
      selected_reason.each do |reason|
        machine_log.select{|jj| jj.updatedate > reason.start_time && jj.enddate <= reason.end_time}
        byebug
      end
    end
    
  end



  def self.report1#(date, shift_no)
    data = []
    date_arr = ('09-02-2020').to_date..('29-02-2020').to_date
    date_arr.each do |dat|   
      date = dat.strftime("%d-%m-%Y")
      all_shift = Shift.all
      all_shift.each do |shift|
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
        machines = L0Setting.pluck(:id, :L0Name)
        machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
        idle_reasons = IdleReasonTransaction.where(:end_time.gte => start_time, :start_time.lte => end_time)
        aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
        machines.each do |machine|
          selected_reason =  idle_reasons.select{|kk| kk.start_time >= start_time && kk.end_time <= end_time && kk.machine_name == machine[1]}
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
          final_data1 = final_data.select{|uu| uu.value == "MANUAL" || uu.value == "ALARM" || uu.value == "EMERGENCY" || uu.value == "STOP" || uu.value == "SUSPEND" || uu.value == "WARMUP" }

          final_data1.each do |rep|
            if rep.value == "EMERGENCY" || rep.value == "ALARM"
            if AlarmHistory.where(:updatedate.gte => rep.updatedate, :enddate.lte => rep.enddate, L0Name: machine[1]).present?
             ins_data = AlarmHistory.where(:updatedate.gte => rep.updatedate, :enddate.lte => rep.enddate, L0Name: machine[1]).first.message
            else
             ins_data = rep.value
            end
          else
            ins_data = selected_reason.select{|a| a.end_time > rep.updatedate && a.start_time < rep.enddate}
            if ins_data.present?
              ins_data = ins_data.first.reason
            else
              ins_data = []
            end
          end     

          if ins_data.present?    
             IdleReasonReport.create(date: date, machine_name: machine[1], reason: ins_data, start_time: rep.updatedate, end_time: rep.enddate, machine_sign: rep.value, shift_num: shift.shift_no, shift_id: shift.id, l0_setting_id: machine[0], duration: rep.timespan) 
          else
            IdleReasonReport.create(date: date, machine_name: machine[1], reason: "NO REASON", start_time: rep.updatedate, end_time: rep.enddate, machine_sign: rep.value, shift_num: shift.shift_no, shift_id: shift.id, l0_setting_id: machine[0], duration: rep.timespan)
          end
        end
      end 
    end
  end 
end



def self.report_last(date, shift_no)
    data = []

    #date_arr = ('01-02-2020').to_date..('29-02-2020').to_date
    #date_arr.each do |dat|
      
    #date = dat.strftime("%d-%m-%Y")
    #all_shift = Shift.all
    #all_shift.each do |shift|
      
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

    machines = L0Setting.pluck(:id, :L0Name)
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    idle_reasons = IdleReasonTransaction.where(:end_time.gte => start_time, :start_time.lte => end_time)
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    machines.each do |machine|
    
     selected_reason =  idle_reasons.select{|kk| kk.start_time >= start_time && kk.end_time <= end_time && kk.machine_name == machine[1]}
     other_data = aa.select{|ii| ii.L1Name == machine[1]} 
      # other_data = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
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
    final_data1 = final_data.select{|uu| uu.value == "MANUAL" || uu.value == "ALARM" || uu.value == "EMERGENCY" || uu.value == "STOP" || uu.value == "SUSPEND" || uu.value == "WARMUP" }
     
    final_data1.each do |rep|
    if rep.value == "EMERGENCY" || rep.value == "ALARM"
      if AlarmHistory.where(:updatedate.gte => rep.updatedate, :enddate.lte => rep.enddate, L0Name: machine[1]).present?
       ins_data = AlarmHistory.where(:updatedate.gte => rep.updatedate, :enddate.lte => rep.enddate, L0Name: machine[1]).first.message
      else
       ins_data = rep.value
      end
    else
      #ins_data = selected_reason.select{|a| a.start_time >= rep.updatedate}.first
      ins_data = selected_reason.select{|a| a.end_time > rep.updatedate && a.start_time < rep.enddate}
      if ins_data.present?
        ins_data = ins_data.first.reason
      else
        ins_data = []
      end
    end                                     
     if ins_data.present?

       IdleReasonReport.create(date: date, machine_name: machine[1], reason: ins_data, start_time: rep.updatedate, end_time: rep.enddate, machine_sign: rep.value, shift_num: shift.shift_no, shift_id: shift.id, l0_setting_id: machine[0], duration: rep.timespan) 
    else
      IdleReasonReport.create(date: date, machine_name: machine[1], reason: "NO REASON", start_time: rep.updatedate, end_time: rep.enddate, machine_sign: rep.value, shift_num: shift.shift_no, shift_id: shift.id, l0_setting_id: machine[0], duration: rep.timespan)
    end
    end

    end
    #end
    #end 
  end



   
end
