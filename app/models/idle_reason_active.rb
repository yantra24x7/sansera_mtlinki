class IdleReasonActive
  include Mongoid::Document
  include Mongoid::Timestamps
  field :machine_name, type: String
  field :time, type: String
  field :date, type: Date 
  field :shift_no, type: Integer
  field :data, type: Array
  field :total, type: Integer

  def self.idle_reason_report(date, shift_no)
     puts "Cron Start"
     puts Time.now
     data = []
     shift = Shift.find_by(shift_no:shift_no)
     # date = "2020-08-22"
#      shift = Shift.current_shift

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
      
      #machines = L0Setting.pluck(:L0Name, :line)
     
      mac_list = L0Setting.pluck(:L0Name, :L0EnName)#.first(2)
      machines = mac_list.map{|i| [i[0], i[1].split('-').first]}

     # machines = L0Setting.all.map{|i| [name: i[:L0Name], line: i[:line]]}.flatten.pluck(:name, :line)
#      machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time)
      
      idle_reason_key = []
      machines.each do |jj|
       idle_reason_key << "MacroVar_755_path1_#{jj[0]}"
      end
      reason_list = IdleReason.all.pluck(:code, :reason).group_by{|kk| kk[0]}
      key_values = L1SignalPool.where(:signalname.in => idle_reason_key, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
      key_value = L1SignalPoolActive.where(:signalname.in => idle_reason_key)
      data = []
      machines.each do |mac|
puts mac[0]       
        all_data = []        
#        aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
#        other_data = aa.select{|ii| ii.L1Name == mac}
#        machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == mac}

        lastdata = key_value.select{|h| h.L1Name == mac[0]}
        all_data = key_values.select{|g| g.L1Name == mac[0]}

        if lastdata.present?
          if (start_time..end_time).include?(lastdata.first.updatedate)
          lastdata.first[:enddate] = Time.now.utc
          all_data << lastdata.first
          end
        end
      
        selected_data = all_data.select{|i| i.value != 0.0 && i.value != nil}
        puts selected_data.pluck(:value) 
        cumulate_idle = []
        if selected_data.present?
          selected_data.each do |reason|
            if reason_list[reason.value.to_i].present?
             cumulate_idle << {idle_reason: reason_list[reason.value.to_i].first[1], idle_start: reason.updatedate,  idle_end: reason.enddate, time: (reason.enddate).to_i - (reason.updatedate).to_i }
            else
             cumulate_idle << {idle_reason: reason_list[reason.value.to_i], idle_start: reason.updatedate,  idle_end: reason.enddate, time: (reason.enddate).to_i - (reason.updatedate).to_i }
            end
          end
        end
          data << {
                 
                   machine_name: mac[0], 
                   time: start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"), 
                   date: date, 
                   shift_no: shift_no, 
                   data: cumulate_idle, 
                   total: cumulate_idle.pluck(:time).sum

                   }
      end
    if data.present?
     
     data.each do |data1|
    # byebug
       unless IdleReasonActive.where(date: data1[:date], shift_no: data1[:shift_no], machine_name: data1[:machine_name]).present?
         IdleReasonActive.create(time: data1[:time], date: data1[:date], shift_no: data1[:shift_no], machine_name: data1[:machine_name],data: data1[:data], total: data1[:total])
      else
        rec = IdleReasonActive.where(date: data1[:date], shift_no: data1[:shift_no], machine_name: data1[:machine_name]).first
        if rec.present?
          rec.update(time: data1[:time], data: data1[:data], total: data1[:total])
        else
        end
      end
     end
    
    end
    puts "END"
   end
 end
















