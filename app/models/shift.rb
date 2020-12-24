class Shift
  include Mongoid::Document
  
  field :start_time, type: String
  field :end_time, type: String
  field :total_hour, type: String
  field :shift_no, type: String
  field :start_day, type: String
  field :end_day, type: String
  field :break_time, type: Integer
  field :total_time, type: Integer
  field :actual_hour, type: Integer
  # belongs_to :OperatorAllocation
  has_many :reports

  validates :start_time, :end_time, :total_hour, :shift_no, :start_day, :end_day, :break_time, presence: true




  def self.current_shift
    shift = []
    shifts = Shift.all
    shifts.map do |ll|
     case
      when ll.start_day == '1' && ll.end_day == '1'
        duration = ll.start_time.to_time..ll.end_time.to_time
        if duration.include?(Time.now)
          shift = ll
        end
      when ll.start_day == '1' && ll.end_day == '2'
        if Time.now.strftime("%p") == "AM"
          duration = ll.start_time.to_time-1.day..ll.end_time.to_time
         else
          duration = ll.start_time.to_time..ll.end_time.to_time+1.day
         end
        if duration.include?(Time.now)
          shift = ll
        end     
      else
        duration = ll.start_time.to_time..ll.end_time.to_time
        if duration.include?(Time.now)
          shift = ll
        end     
      end
    end
    return shift
  end


  def self.report(date, shift_no)
    data = []
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

    machines = L0Setting.pluck(:L0Name)
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine, mainprogflg: true)
    
    ll = prog.select{|hh| hh.mainprog == hh.runningprog }
    
      m_p_result = p_result.select{|m| m.L1Name == machine && m.updatedate > start_time}
      production_name = m_p_result.select{|kk| kk.productresult != 0}.pluck(:productname).uniq
     
      other_data = aa.select{|ii| ii.L1Name == machine}
      
      # other_data = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
      machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == machine}  
        
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
    utilisation= ((run_time*100) / duration)
     
     
     
      data << {
      date: date,
      shift_num: shift_no,
      shift_id: shift.id,
      machine_name: machine,
      run_time: run_time,
      idle_time: idle_time,
      disconnect: disconnect,
      part_count: m_p_result.pluck(:productresult).map(&:to_i).sum,
      part_name: production_name,
      program_number: ll.pluck(:mainprog).uniq,
      duration: duration,
      utilisation: utilisation,
      part: m_p_result
    }
    end

   data.each do |data1|
    
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        Report.create(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name] , run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation])
      else
        puts "Already Data Exists"
      end

   end
  end 

 

  def self.delayed_job
# dates = Date.today.beginning_of_month - 1.month .. Date.today.end_of_month - 1.month
#dates.each do |da|
    date = Date.today.strftime("%d-%m-%Y")
  #  date = da.strftime("%d-%m-%Y")   
 Shift.all.each do |shift|
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
      unless Delayed::Job.where(run_at: end_time + 2.minutes).present?
        OeeCalculation.delay(run_at: end_time + 2.minutes).report(date,shift.shift_no)
      end
#      unless Delayed::Job.where(run_at: end_time + 4.minutes).present?
#        Report.delay(run_at: end_time + 4.minutes).report_last(date,shift.shift_no)
#      end
  
    end
 # end
  end

 def self.report2(date, shift_no)
    data = []
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

    machines = L0Setting.pluck(:L0Name)
    machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine, mainprogflg: true)
    
    ll = prog.select{|hh| hh.mainprog == hh.runningprog }
     
      m_p_result = p_result.select{|m| m.L1Name == machine }#&& m.updatedate > start_time}

      production_name = m_p_result.select{|kk| kk.productresult != 0}.pluck(:productname).uniq
     
      other_data = aa.select{|ii| ii.L1Name == machine}
      
      # other_data = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
      machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == machine}  
        
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
    utilisation= ((run_time*100) / duration)
      
      data << {
      date: date,
      shift_num: shift_no,
      shift_id: shift.id,
      machine_name: machine,
      run_time: run_time,
      idle_time: idle_time,
      disconnect: disconnect,
      part_count: m_p_result.pluck(:productresult).map(&:to_i).sum,
      part_name: production_name,
      program_number: ll.pluck(:mainprog).uniq,
      duration: duration,
      utilisation: utilisation
    }
    end
      data.each do |data1|
      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?
        Report.create(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name] , run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation])
      else
        puts "Already Data Exists"
      end

   end
  end  
    end
