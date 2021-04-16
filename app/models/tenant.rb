class Tenant
  include Mongoid::Document
  include Mongoid::Timestamps
  field :tenant_name, type: String
  field :address_line1, type: String
  field :address_line2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :pincode, type: String

  def self.dashboard
     puts Time.now
      date = Date.today.to_s
    data = []
    shift = Shift.current_shift#.find_by(shift_no:shift_no)
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
     mac_list = L0Setting.pluck(:L0Name, :L0EnName)
     machines1 = mac_list.map{|list| list[0]}
     machines = mac_list.map{|i| [i[0], i[1].split('-').first]}
     duration = (end_time - start_time).to_i
   
    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate).group_by{|dd| dd[:L1Name]}
    byebug
  end





  def self.report(date, shift_no)
    puts Time.now
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
     mac_list = L0Setting.pluck(:L0Name, :L0EnName)
     machines1 = mac_list.map{|list| list[0]}
     machines = mac_list.map{|i| [i[0], i[1].split('-').first]}
     duration = (end_time - start_time).to_i
     
     key_list = []
     machines.each do |jj|
       key_list << "MacroVar_604_path1_#{jj[0]}"
       key_list << "MacroVar_705_path1_#{jj[0]}"
     end
     
    machine_log = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time).only(:L1Name, :value, :timespan, :updatedate, :enddate, :default).group_by{|dd| dd[:L1Name]}
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time).count#.group_by{|kk| kk[:L1Name]}#.only(:L1Name, :timespan, :updatedate, :enddate, :productname, :productresult, :productresult_accumulate).group_by{|kk| kk[:L1Name]}
   puts p_result
# machine_signals = L1SignalPool.where(:signalname.in => key_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)#.group_by{|kk| kk[:L1Name]}#.only(:L1Name, :timespan, :updatedate, :enddate, :signalname, :value).group_by{|dd| dd[:L1Name]}
# puts machine_signals.count
#byebug
# last_machine_signal =  L1SignalPoolActive.where(:signalname.in => key_list)
#LOG
    bls = machines1 - machine_log.keys
    mer_req = bls.map{|i| [i,[]]}.to_h
    machine_logs = machine_log.merge(mer_req)
#Part
   # bls2 = machines1 - p_result.keys
   # mer_req2 = bls2.map{|i| [i,[]]}.to_h
   # p_result = p_result.merge(mer_req2)
#SIG
   # bls3 = machines1 - machine_signal.keys
   # mer_req3 = bls.map{|i| [i,[]]}.to_h
   # machine_signal = machine_signal.merge(mer_req3)
#puts Time.now
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
      value << L1Pool.new(updatedate: start_time, enddate: end_time, timespan: duration, value: "DISCONNECT", default: duration)
    elsif value.count == 1
      value.first[:updatedate] = start_time
      value.first[:enddate] = end_time
      value.first[:timespan] = (end_time - start_time).to_i
      value.first[:default] = (end_time - start_time).to_i
    else
      value.first[:updatedate] = start_time
      value.first[:timespan] = (value.first.enddate.to_time - start_time)
      value.first[:default] = (value.first.enddate.to_time - start_time)
      value.last[:enddate] = end_time
      value.last[:timespan] = (end_time - value.last.updatedate.to_time)
      value.last[:default] = (end_time - value.last.updatedate.to_time)
    end   

    group_split =  value.group_by{|gg|gg[:value]}
    puts value.pluck(:default).sum
    group_split.each do |k,v|
     case
      when k == "OPERATE"
        operate << v.pluck(:default).sum
      when k == "MANUAL"
        manual << v.pluck(:default).sum
      when k == "DISCONNECT"
        disconnect << v.pluck(:default).sum
      when k == "ALARM"
        alarm << v.pluck(:default).sum
      when k == "EMERGENCY"
        emergency << v.pluck(:default).sum
      when k == "STOP"
        stop << v.pluck(:default).sum
      when k == "SUSPEND"
        suspend << v.pluck(:default).sum
      when k == "WARMUP"
        warmup << v.pluck(:default).sum
      end
    end

    total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
    bls = duration - total_running_time
    run_time = operate.sum
    idle_time = (manual.sum + stop.sum + suspend.sum + warmup.sum)
    alarm_time = (alarm.sum + emergency.sum)
    disconnect = (disconnect.sum + bls)
    utilisation = ((run_time*100) / duration)
    # === Production Start === #
  #  route_signals = machine_signals.select{|ss| ss.L1Name == key[0] && ss.signalname == "MacroVar_604_path1_#{key[0]}"}
  #  route_signal = last_machine_signal.select{|s| s.L1Name == key[0] && s.signalname == "MacroVar_604_path1_#{key[0]}"}
    puts Time.now
    route_signals = L1SignalPool.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time, :signalname => "MacroVar_604_path1_#{key[0]}").pluck(:signalname)

puts Time.now


    route_signal = L1SignalPoolActive.where(:signalname => "MacroVar_604_path1_#{key[0]}")
    puts Time.now
    puts route_signals.count
    puts route_signal.count
    puts Time.now
    byebug
    # === Production End === #
   end#mac
  
     
  end


end
