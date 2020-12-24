class Operator
  include Mongoid::Document
  include Mongoid::Paranoia

  field :operator_name, type: String
  field :operator_spec_id, type: String
  field :description, type: String
  field :isactive, type: Mongoid::Boolean
  field :deleted_at, type: DateTime

  validates :operator_spec_id, uniqueness: true
  validates :operator_name, :operator_spec_id, presence: true


  def self.live_report
    data = []
    oee_data = []
  
    date = Date.today.strftime("%d-%m-%Y")  
    #shift = Shift.current_shift
    shift = Shift.find_by(shift_no: 2)

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
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    
    machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true)
    
    ll = prog.select{|hh| hh.mainprog == hh.runningprog }
      
      #m_p_result = p_result.select{|m| m.L1Name == machine && m.updatedate > start_time}
      m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time}
      p_part_data = []
      oee_data_result = []
      m_p_result.each do |part|
        if part.productresult != '0'
          pg_group = prog.select{|b| b.updatedate >= part.updatedate && b.enddate <= part.enddate}
          if pg_group.present?
            pg_num = pg_group.pluck(:mainprog).last.split('/').last
          else 
            dd = prog.select{|b| b.enddate > part.updatedate }
            dd_2 = dd.select{|c| c.updatedate < part.enddate}
            
            if dd_2.present?
              pg_num = dd_2.pluck(:mainprog).last.split('/').last
            else
              pg_num = "NO PGM"
            end
          end
            if ProductionPart.where(date: date, part_start_time: part.updatedate, part_end_time: part.enddate).present?  
            else
              ProductionPart.create(date: date, shift_num: shift.shift_no, machine_name: machine[1], part_count: part.productresult_accumulate, program_number: pg_num, part_start_time: part.updatedate, part_end_time: part.enddate, cycle_time: nil, cutting_time: nil, productname: part.productname, productresult: part.productresult.to_i, productresult_accumulate: part.productresult_accumulate, timespan: part.timespan, accept_count: 1, reject_count: nil, is_verified: false, l0_setting_id: machine[0], shift_id: shift.id)
            end
          #p_part_data << {date: date, shift_num: shift.shift_no, machine_name: machine[1], part_count: part.productresult_accumulate, program_number: pg_num, part_start_time: part.updatedate, part_end_time: part.enddate, cycle_time: nil, cutting_time: nil, productname: part.productname, productresult: part.productresult.to_i, productresult_accumulate: part.productresult_accumulate, timespan: part.timespan, accept_count: nil, reject_count: nil, is_verified: false, l0_setting_id: machine[0], shift_id: shift.id}
        end  
      end
      
      
      oee_data = OeeCalculation.where(date: date, shift_num: shift.shift_no, l0_setting_id: machine[0])
      production = ProductionPart.where(date: date, shift_num: shift.shift_no, l0_setting_id: machine[0])
      rec_oee = oee_data.pluck(:idle_run_rate)
      rec_oee.flatten.each do |tar|
        total = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] }
        accept_count = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] && dd.accept_count == 1 }
        reject_count = production.select{|dd| dd.program_number.split('/').last == tar["program_number"] && dd.reject_count == 1 }
        oee_data_result << {program_number: tar["program_number"], count: total.count, accept_count: accept_count.count, reject_count: reject_count.count}
      end

      if oee_data.present?
        oee_data.last.update(actual_idle_run_rate: oee_data_result)
      end

      report_oee_data = production.group_by(&:program_number).map{|i| {i[0] => i[1].pluck(:productresult).sum}}
      
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
    idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
    alarm_time = (alarm.sum + emergency.sum)  
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)
     
    
     
      data << {
      date: date,
      shift_num: shift.shift_no,
      shift_id: shift.id,
      machine_name: machine[1],
      run_time: run_time,
      idle_time: idle_time,
      alarm_time: alarm_time,
      disconnect: disconnect,
      part_count: m_p_result.pluck(:productresult).map(&:to_i).sum,
      part_name: production_name,
      program_number: production.pluck(:program_number).uniq,
      duration: duration,
      utilisation: utilisation,
      #part: p_part_data
      oee: report_oee_data
    }
    end
    
    data.each do |data1|
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        report = Report.create(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time])    
      else  
        report = Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).last
        report.update(run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time])
      end
    end
  end

end
