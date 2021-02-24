class CurrentStatus
  include Mongoid::Document
  field :date, type: Date
  field :shift_num, type: Integer
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :data, type: Array
  field :up_time, type: DateTime
 
  field :r_date, type: Date
  field :r_shift_num, type: Integer
  field :r_start_time, type: DateTime
  field :r_end_time, type: DateTime
  field :r_data, type: Array
  field :r_up_time, type: DateTime

   def self.current_shift_report
      data2 = [] 
      puts "Cron Start"
      puts Time.now
      date = Date.today.to_s
     # date = "2020-08-22"
      shift = Shift.current_shift
      # date = (Date.today - 2.day).to_s    
     #  shift = Shift.find_by(shift_no: 1)
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
     # machines = L0Setting.where(L0Name: "SDD-1104").pluck(:L0Name)
     # mac_with_line = L0Setting.pluck(:L0Name, :line).group_by(&:first)
     # byebug
      mac_list = L0Setting.pluck(:L0Name, :L0EnName)
      mac_with_line = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by(&:first)


      machines = L0Setting.pluck(:L0Name)
    # abc = Time.now
      machine_logs = L1Pool.where(:enddate.gte => start_time, :updatedate.lte => end_time, :value.in => status)     
   #  xyz = Time.now
    # byebug
#     puts (xyz.to_i - abc.to_i)
    # byebug

      active_machine_log = L1SignalPoolActive.where(:signalname.in => status, value: true)
      machines.each do |mac|
#         if mac == 'ELECTRICAL-C84'
#         byebug
#         end          
             
               
          aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
          other_data = aa.select{|ii| ii.L1Name == mac}
          machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == mac}
         # active_machine_log = L1SignalPoolActive.where(:signalname.in => status, value: true, L1Name: mac)
         #  byebug 
          status = active_machine_log.select{|j| j.L1Name == mac}
	 if status.present?
          case
          when status.first.signalname == 'OPERATE'
           status1 = 'OPERATE'
          else
           status1 = 'STOP'
          end
         else
           status1 = 'DISCONNECT'
         end
        # end

      #    if machine_log.count == 0
      #      status1 = 'DISCONNECT'
      #    else
      #      if machine_log.last.value == 'OPERATE'
      #        status1 = 'OPERATE'
      #      elsif machine_log.last.value == 'DISCONNECT'
      #        status1 = 'DISCONNECT'
      #      else
      #        status1 = 'STOP'
      #      end   
      #    end
          
          other_data.each do |torcher_data|
            case 
            when torcher_data.updatedate.localtime < start_time.localtime && torcher_data.enddate.localtime > end_time.localtime
              time_span = end_time - start_time
              machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: end_time, timespan: time_span, signalname: torcher_data.value, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
            when torcher_data.updatedate.localtime < start_time.localtime
              time_span = torcher_data.enddate.localtime - start_time
              machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: torcher_data.enddate, timespan: time_span, signalname: torcher_data.value, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
            when torcher_data.enddate.localtime > end_time.localtime   
              time_span = end_time - torcher_data.updatedate.localtime
              machine_log << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: torcher_data.updatedate, enddate: end_time, timespan: time_span, signalname: torcher_data.value, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
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

            puts mac
          
     
          data2 << {
            machine: mac,
            line: mac_with_line[mac].first[1],
            status: status1,
            run_time: ((run_time*100).round/duration.to_f).round(1),
            idle_time: ((idle_time*100).round/duration.to_f).round(1),
            disconnect: ((disconnect*100).round/duration.to_f).round(1),
            orig: run_time
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
        line:bb[:line],
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
    puts "Cron End"
      puts Time.now
  
    if CurrentStatus.first.present?
      dd = CurrentStatus.first
       
        dd.update(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third, time: Time.now.localtime}])
     
    else
      CurrentStatus.create(up_time: Time.now, start_time: start_time, end_time: end_time, data: [{first:  first, second: second, third: third , time: Time.now.localtime}])
    end

end



   def self.eff_report#(date, shift_no)
  #  puts Time.now
     date = Date.today.to_s
     # date = "2020-08-22"
     shift = Shift.current_shift
    data = []
    oee_data = []
   # shift = Shift.find_by(shift_no: shift_no)
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
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    machines = mac_list.map{|i| [i[0], i[1].split('-').first]}

    key_list = []
    machines.each do |jj|
    key_list << "MacroVar_751_path1_#{jj[0]}"
    end

    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)#.group_by{|kk| kk[:L1Name]}
    key_values = L1SignalPool.where(:signalname.in => key_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)
    key_value = L1SignalPoolActive.where(:signalname.in => key_list)
    components = Component.all


   final_data = []
      machines.each do |key|
      puts "-----------------------"
      puts "---**---#{key[0]}---**----"

     puts (Time.now).localtime
      puts (Time.now).localtime
      lastdata = key_value.select{|h| h.L1Name == key[0]}
      all_data = key_values.select{|g| g.L1Name == key[0]}


      if lastdata.present?
       lastdata.first[:enddate] = Time.now.utc
       all_data << lastdata.first
      end
      time_target = []


      if all_data.present?
       if all_data.count == 1
        all_data.first[:updatedate] = start_time
        all_data.first[:enddate] = end_time
        all_data.first[:timespan] = (end_time - start_time).to_i
       else
        all_data.first[:updatedate] = start_time
        all_data.first[:timespan] = (all_data.first.enddate.to_time - start_time)
        all_data.last[:enddate] = end_time
        all_data.last[:timespan] = (end_time - all_data.last.updatedate.to_time)
       end


       all_data.each do |kvalue|
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
        cumulate_data = time_target.split("##")
        cumulate_data.each do |kk|
          comp_id = kk.pluck(:value).compact.uniq.first
          st_time = kk.first.updatedate
          en_time = kk.last.enddate
          tr_data << {comp_id: comp_id, st_time:st_time, ed_time: en_time}
        end
      end


      compiled_component = []
      tt = tr_data.count



      if tr_data.present?
      if tr_data.count == 1


      run_compinent = tr_data.first[:comp_id].to_i
      sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == key[0]}
       if sel_comp.present?
        tar = sel_comp.first.target
        production_count = p_result.select{|sel| sel.enddate > tr_data.first[:st_time].localtime && sel.updatedate < tr_data.first[:ed_time].localtime && sel.L1Name == key[0] && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum
        if tar.to_f == 0.0
        effe = 0
        else
        effe = production_count.to_f/tar.to_f
        end
        effi = (effe * 100).to_i
        final_data << {machine: key[0], efficiency: effi, line: key[1], tar: tar, actual:  production_count}
         puts "#{tt} DATA"

         puts "NO COUNT"
       else
         puts "#{tt} DATA"
                puts "NO COUNT"
       final_data << {machine: key[0], efficiency: 0, line: key[1], tar: 0, actual: 0}
       end
      else

      tr_data.each do |data|

        run_compinent = data[:comp_id].to_i
        sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == key[0]}
         if sel_comp.present?
         tar = sel_comp.first.target
         production_count = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key[0] && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum
         sing_part_time = shift.actual_hour/tar
         run_hr = data[:ed_time].to_i - data[:st_time].to_i
         target = run_hr/sing_part_time
         if target == 0.0
         effe = 0
         else
         effe = production_count.to_f/target.to_f
         end
         effi = (effe * 100).to_i
        # compiled_component << {machine: key[0], efficiency: effi}
         compiled_component << {machine: key[0], efficiency: effi, line: key[1], tar: target, actual: production_count}
         puts "#{tt} DATA"
         puts "NO COUNT"
       else
         puts "#{tt} DATA"
         puts "NO COUNT"
         compiled_component << {machine: key[0], efficiency: 0, line: key[1],tar: 0, actual: 0}
        # compiled_component << {machine: key[0], efficiency: 0}
        end
      end
      end
      else
        puts "NO DATA"
        puts "NO COUNT"
        compiled_component << {machine: key[0], efficiency: 0, line: key[1], tar: 0, actual: 0}
     #   compiled_component << {machine: key[0], efficiency: 0}
      end

         if compiled_component.present?
        effi1 = compiled_component.pluck(:efficiency).sum/compiled_component.count
        tot_tar = compiled_component.pluck(:tar).sum
        act_tar = compiled_component.pluck(:actual).sum
        final_data << {machine: key[0], efficiency: effi1, line: key[1],tar: tot_tar, actual: act_tar}
      end



     puts (Time.now).localtime
    end#machine

    result_data = []
    final_data.group_by{|d| d[:line]}.map do |key1,value1|
     if key1 == nil
       f_name = "Line1-1"
     else
       f_name = key1
     end
     over_all_effi = value1.pluck(:efficiency).sum/value1.count
     low_perfom = value1.group_by { |x| x[:efficiency] }.min.last.first[:machine]
     log_per_tar = final_data.select{|i| i[:machine] == low_perfom}
     if log_per_tar.present?
      lpt = log_per_tar.first[:tar]
      lpa = log_per_tar.first[:actual]
     else
      lpt = 0
      lpa = 0
     end
     mac_list = value1.pluck(:machine)
     result_data << {Line: f_name, eff: over_all_effi, low_perf_machine: low_perfom, machine_list: mac_list, lpt: lpt, lpa: lpa}
    end

    #  end


  if CurrentStatus.first.present?
      dd = CurrentStatus.first

        dd.update(r_up_time: Time.now, r_start_time: start_time, r_end_time: end_time, r_data: final_data)
    else
      CurrentStatus.create(r_up_time: Time.now, r_start_time: start_time, r_end_time: end_time, r_data: final_data)
    end



  end

















end
