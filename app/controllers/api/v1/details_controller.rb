module Api
  module V1
  	class DetailsController < ApplicationController
  		
      # -----> LMW <----- #
      def all_machine_current_status
       date = (Date.today - 1.days).to_s
       #shift = Shift.current_shift
       
       shift = Shift.find_by(shift_no: 4)
       # case
       #  when shift.start_day == 1 && shift.end_day == 1
       #    start_time = (date+" "+shift.start_time).to_time
       #    end_time = (date+" "+shift.end_time).to_time
       #  when shift.start_day == 1 && shift.end_day == 2
       #     if Time.now.strftime("%p") == "AM"
       #      start_time = (date+" "+shift.start_time).to_time-1.day
       #      end_time = (date+" "+shift.end_time).to_time
       #    else
       #      start_time = (date+" "+shift.start_time).to_time
       #      end_time = (date+" "+shift.end_time).to_time+1.day
       #    end
       #  else
       #    start_time = (date+" "+shift.start_time).to_time
       #    end_time = (date+" "+shift.end_time).to_time
       #  end
      case
      when shift.start_day == "1" && shift.end_day == "1"
        start_time = (date+" "+shift.start_time).to_time
        end_time = (date+" "+shift.end_time).to_time
      when shift.start_day == "1" && shift.end_day == "2"
        start_time = (date+" "+shift.start_time).to_time
        end_time = (date+" "+shift.end_time).to_time+1.day
      else
        start_time = (date+" "+shift.start_time).to_time+1.day
        end_time = (date+" "+shift.end_time).to_time+1.day
      end



        #machine_logs = L1SignalPool.where(enddate: DateTime.now.at_beginning_of_day..Time.now)
        data = []
        status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']

        machine_log = L1SignalPoolCapped.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: 'machine1', :signalname.in => status, value: true)
        
        # case
        #   when machine_log.first.updatedate.localtime <= start_time.localtime
        #     puts "okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkfirst"
        #   when machine_log.last.enddate.localtime > end_time.localtime
        #     puts "okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkklast"
        #   end
       
       machine_log88 = machine_log.where(:updatedate.gte => start_time, :enddate.lte => end_time)
       
       ids = machine_log88.pluck(:id)
       other_data = other_data = machine_log.not_in(id: ids)
       aa = []
       
       machine_log68 = machine_log88.to_a
       
       other_data.each do |torcher_data|
        case 
        when torcher_data.updatedate.localtime < start_time.localtime && torcher_data.enddate.localtime > end_time.localtime
          time_span = end_time - start_time
          machine_log68 << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: end_time, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
        when torcher_data.updatedate.localtime < start_time.localtime
          time_span = torcher_data.enddate.localtime - start_time
          machine_log68 << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: start_time, enddate: torcher_data.enddate, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
        when torcher_data.enddate.localtime > end_time.localtime   
          time_span = end_time - torcher_data.updatedate.localtime
          machine_log68 << L1SignalPoolCapped.new(id:torcher_data.id, L1Name: torcher_data.L1Name, updatedate: torcher_data.updatedate, enddate: end_time, timespan: time_span, signalname: torcher_data.signalname, value: true, filter: nil, TypeID: nil, Judge: nil, Error: nil, Warning: nil)
        end
       end
        
        machine_log68 = sorted = machine_log68.sort_by &:updatedate 
        machine_log68.each_with_index do |value, index|
          st_time = value.updatedate.localtime.strftime("%d-%m-%Y %H:%M").to_time
          en_time = value.enddate.localtime.strftime("%d-%m-%Y %H:%M").to_time
          #end
          
          data << {
          
           status: value.signalname,
           #start_time: da.updatedate.localtime,
           #end_time: da.enddate.localtime,
           start_time: st_time,#da.updatedate.localtime.strftime("%d-%m-%Y %H:%M").to_time,
           end_time: en_time,   #da.enddate.localtime.strftime("%d-%m-%Y %H:%M").to_time,
           #duration: (da.enddate .localtime - da.updatedate.localtime).to_i
           duration: (en_time - st_time) #(da.enddate.localtime.strftime("%d-%m-%Y %H:%M").to_time) - (da.updatedate.localtime.strftime("%d-%m-%Y %H:%M").to_time)
          }
        end

        
        data1 = []
        temp = []
        data.group_by{|ii| ii[:status]}.each do |k, v|
          
          data1 << {
            status: k,
            tot_time: v.pluck(:duration).sum,
            rate: ((v.pluck(:duration).sum)*100)/(end_time-start_time).round(1)
          }
          temp << ((v.pluck(:duration).sum)*100)/(end_time-start_time).round(1)
        end
        
        
        act =  data1.pluck(:tot_time).sum
        #extra = pre+nex
        #sum = act + extra
        shift_time = end_time-start_time
        diff = shift_time - act

        render json: {temp: temp,act: act, shift_time: shift_time, diff: diff, data: data1, signal: data }
      end

      def lmw_dashboard2
        
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
        
        
        cur_st = CurrentStatus.last
        if cur_st.start_time.localtime == start_time.localtime &&  cur_st.end_time.localtime == end_time.localtime
          render json: cur_st.data.first
        else
       
        duration = (end_time - start_time).to_i
        status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
        machines = L0Setting.pluck(:L0Name)
        machine_logs = L1SignalPoolCapped.where(:enddate.gte => start_time, :updatedate.lte => end_time, :signalname.in => status, value: true)      

        machines.map do |mac|
          aa = machine_logs.select{|jj| jj.updatedate < start_time || jj.enddate > end_time}
          other_data = aa.select{|ii| ii.L1Name == mac}
          machine_log = machine_logs.select{|kk| kk.updatedate >= start_time && kk.enddate <= end_time && kk.L1Name == mac}
          #machine_log = machine_logs.where(:updatedate.gte => start_time, :enddate.lte => end_time, :L1Name => mac)
          #other_data = machine_logs.where(L1Name: mac).not_in(id: machine_log.pluck(:id))
          active_machine_log = L1SignalPoolActive.where(:signalname.in => status, value: true, L1Name: mac)
          #byebug
            
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



         # first << {
         #  utlization: bb[:run_time],
         #  name:bb[:machine],
         #  status: bb[:status],
         #  run_time: bb[:run_time],
         #  stop: bb[:idle_time],
         #  disconnect: bb[:disconnect]
         #  }
         
         first << {
          utlization: c_run_time.round(0),
          name:bb[:machine],
          status: bb[:status],
          run_time: c_run_time,
          stop: c_idle_time,
          disconnect: c_disconnect
          }
        end
        #byebug
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
        
     #byebug

       #  third = [
       #   ["Running", ((first.pluck(:run_time).sum)/machines.count).round(1)],
       #   ["Stop", ((first.pluck(:stop).sum)/machines.count).round(1)],
       #   ["Disconnect", ((first.pluck(:disconnect).sum)  /machines.count).round(1)]     
       # ]

         third = [
         ["Running",over_all_value[0]],
         ["Stop", over_all_value[1]],
         ["Disconnect", over_all_value[2]]     
       ]



       
      render json: {first:  first, second: second, third: third } 
      end
    end
  		
      # def all_machine_current_status2


      # end

      def lmw_dashboard
        date = Date.today.to_s
        shift = Shift.current_shift
       case
        when shift.start_day == 1 && shift.end_day == 1
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        when shift.start_day == 1 && shift.end_day == 2
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
        duration = end_time - start_time
        
        machines = L0Setting.pluck(:L0Name)
        status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
        machine_log_all = L1SignalPoolCapped.where(:enddate.gte => start_time, :updatedate.lte => end_time, :signalname.in => status, value: true)
        #machine_log_all = L1SignalPoolCapped.where(:enddate.gte => start_time, :updatedate.lte => end_time)
        data = []
        machines.map do |mac|
          machine_log = L1SignalPoolActive.where(:signalname.in => status, value: true, L1Name: mac)
          machine_log_with_all = machine_log_all.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: mac, :signalname.in => status, value: true)
          machine_logs = machine_log_with_all.where(:signalname.in => ['OPERATE'])
          
          if machine_log.count == 0
            status1 = 'DISCONNECT'
          else
            if machine_log.first.signalname == 'OPERATE'
              status1 = 'OPERATE'
            elsif machine_log.first.signalname == 'DISCONNECT'
              status1 = 'DISCONNECT'
            else
              status1 = 'STOP'
            end   
          end

          data << {
 
            utlization: (machine_logs.pluck(:timespan).sum.round)*100/(duration).to_i,
            name: mac,
            #status: machine_log1.first.signalname
            status: status1#,
            #tt: machine_logs.pluck(:timespan).sum.round
          }
        end

        machine_group = machine_log_all.group_by{|ii| ii[:L1Name]} 
        data2 = []
        machine_group.each.map do |k,v|

          #dis = v.select{|i| i.signalname == 'DISCONNECT'}.pluck(:timespan).sum
         
          ope = v.select{|i| i.signalname == 'OPERATE'}.pluck(:timespan).sum.round()
          stop = v.select{|i| i.signalname != 'OPERATE' && i.signalname != 'DISCONNECT' }.pluck(:timespan).sum
          tot_ope = ope + stop
          bls = duration.to_i - tot_ope

          production = machine_log_all.where(signalname: "ProductResultNumber", L1Name: k).pluck(:value).count
                
          data2 <<
          {
            operate: ope,
            operate_percentage: ((ope * 100)/duration).round(),
            disconnect: ((bls * 100)/duration).round(),
            stop: ((stop * 100)/duration).round(),
            machine: k,
            production: production

          }
        end
         
        #data5 = []
        data4 = data2.sort_by!(&:zip).reverse!

        data5 = {
        Machine: data4.pluck(:machine),
        Running: data4.pluck(:operate_percentage),
        Stop: data4.pluck(:stop),
        Disconnect: data4.pluck(:disconnect),
        production: data4.pluck(:production)
      } 


        
        data3 = [] 
        tot_dur = duration*machines.count
        
        tot_operate_time = machine_log_all.select{|j| j.signalname == 'OPERATE'}.pluck(:timespan).sum
        tot_stop_time = machine_log_all.select{|j| j.signalname != 'OPERATE' && j.signalname != 'DISCONNECT'}.pluck(:timespan).sum
        
        tot_bal = tot_dur - (tot_operate_time + tot_stop_time)
        data3 = [
        ["Running", ((tot_operate_time*100)/tot_dur).round()],
        ["Stop",((tot_stop_time*100)/tot_dur).round()],
        ["Disconnect", ((tot_bal*100)/tot_dur).round()]
        ] 
        # machine_log.group_by{|ii| ii[:L1Name]}.each do |ii|
        #   byebug
        #   data << {
        #     status: ii[0],
        #     tot_time: v.pluck(:duration).sum,
        #     rate: ((v.pluck(:duration).sum)*100)/(end_time-start_time).round(1)
        #   }
        # end
        #data = data1
        render json: {first: data.sort_by!(&:zip).reverse!, second: data5, third: data3}
      end
      


        
   # end
      def mtlink_dashboard
	        # machines = L0Setting.pluck(:L0Name)
	        # machines.map{|i| CncState_path1_'#{i}'}
	        machines = L0Setting.pluck(:L0Name).map{|i| "CncState_path1_#{i}"}
	        data = L1SignalPoolActive.where(:signalname.in => machines)
  	  		
  	  		# data.pluck(:value).map do |i|
  	  		# 	case 
       #      when i == "OPERATE"
       #        @status = 3
       #      when i == "STOP"
       #        @status = 1
       #      else
       #        @status = 0
       #      end
  	  		# end
# byebug
          ans = []
          data.map do |i|
            mac_name = i.L1Name
            status = i.value
            ans.push(:machine_name => mac_name, :machine_status => status)
          end
  # byebug
          render json: {data: ans}
  	  	end

        

        
        
  	end
  end
end
