class CurrentStatus
  include Mongoid::Document
  field :date, type: Date
  field :shift_num, type: Integer
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :data, type: Array

    def self.current_shift_report
      data2 = []  
      date = Date.today.to_s
      shift = Shift.current_shift
      # date = (Date.today - 2.day).to_s    
      # shift = Shift.find_by(shift_no: 4)
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
      
      duration = (end_time - start_time).to_i
      status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
      machines = L0Setting.pluck(:L0Name)
      machine_logs = L1SignalPoolCapped .where(:enddate.gte => start_time, :updatedate.lte => end_time, :signalname.in => status, value: true)     
      machines.map do |mac|
          
          aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
          other_data = aa.select{|ii| ii.L1Name == mac}
          machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == mac}
          active_machine_log = L1SignalPoolActive.where(:signalname.in => status, value: true, L1Name: mac)
            
          if machine_log.count == 0
            status1 = 'DISCONNECT'
          else
            if machine_log.last.signalname == 'OPERATE'
              status1 = 'OPERATE'
            elsif machine_log.last.signalname == 'DISCONNECT'
              status1 = 'DISCONNECT'
            else
              status1 = 'STOP'
            end   
          end
          
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
            when dat.signalname == "OPERATE"
              operate << dat.timespan
            when dat.signalname == "MANUAL"
              manual << dat.timespan
            when dat.signalname == "DISCONNECT"
              disconnect << dat.timespan
            when dat.signalname == "ALARM"
              alarm << dat.timespan
            when dat.signalname == "EMERGENCY"
              emergency << dat.timespan
            when dat.signalname == "STOP"
              stop << dat.timespan
            when dat.signalname == "SUSPEND"
              suspend << dat.timespan
            when dat.signalname == "WARMUP"
              warmup << dat.timespan
            end
          end
          
          total_running_time = operate.sum + manual.sum + disconnect.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum
          bls = duration - total_running_time
          run_time = operate.sum
          idle_time = (manual.sum + alarm.sum + emergency.sum + stop.sum + suspend.sum + warmup.sum)
          disconnect = (disconnect.sum + bls)

            
          data2 << {
            machine: mac,
            status: status1,
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
        status: bb[:status],
        run_time: c_run_time,
        stop: c_idle_time,
        disconnect: c_disconnect
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

      over_all_utlize = [((first.pluck(:run_time).sum)/machines.count).round(1),((first.pluck(:stop).sum)/machines.count).round(1),((first.pluck(:disconnect).sum)  /machines.count).round(1)]
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
    
  
    if CurrentStatus.first.present?
      dd = CurrentStatus.first
       
        dd.update(start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third }])
     
    else
      CurrentStatus.create(start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third }])
    end

   end
end
