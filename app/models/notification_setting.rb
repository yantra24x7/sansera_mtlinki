class NotificationSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :L0Name, type: String
  field :mean_time, type: Integer    
  field :last_notifi_time, type: DateTime
  field :active, type: Mongoid::Boolean 
  belongs_to :l0_setting

   validates :L0Name, uniqueness: true
   validates :L0Name, presence: true


  def self.create_data
   L0Setting.each do |aa|
     NotificationSetting.create(L0Name: aa.L0Name, mean_time: 600, l0_setting_id: aa.id, active: false)
   end
  end 

 def self.sent_notification
 # NotificationMailer.notification("test") 
 mac_list = L1PoolOpened.all
 data = []
 mac_list.each do |rec|
  if  rec.value == "STOP"
    time_rec = (Time.now - rec.updatedate).to_i
  if time_rec > 900
   data << rec
  end
  end
 end
  if data.present?
  NotificationMailer.notification(data).deliver_now
  end
 end


  def self.test_thread
   a = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
   threads = []
   a.each_slice(5) do |group| 
    threads << Thread.new(group) do  |tsrc|
      tsrc.each do |user|
        #puts ex_request
         puts user
        # sleep 10
      end
    end
end
end



  def self.dashboard#(date, shift_no)
    all_data = []
    date = Date.today.to_s
    
   # shift = Shift.current_shift
   # case
   # when shift.start_day == '1' && shift.end_day == '1'
   #   start_time = (date+" "+shift.start_time).to_time
   #   end_time = (date+" "+shift.end_time).to_time
   # when shift.start_day == '1' && shift.end_day == '2'
   #   start_time = (date+" "+shift.start_time).to_time
   #   end_time = (date+" "+shift.end_time).to_time+1.day
   # else
   #   start_time = (date+" "+shift.start_time).to_time+1.day
   #   end_time = (date+" "+shift.end_time).to_time+1.day
   # end



#    duration = (end_time - start_time).to_i

    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[0]}
    machines = mac_lists.keys
    operators = Operator.all.pluck(:operator_spec_id, :operator_name).group_by(&:first)
    mac_sett = MachineSetting.where(group_signal: "MacroVar").group_by{|d| d[:L1Name]}
 
    if mac_sett.present?
    macro_list = mac_sett.values.map{|i| i.first.value}.sum
    else
    macro_list = []
    end

#    stt_time = start_time.strftime("%Y-%m-%d %H:%M:%S")#start_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")
#    edd_time = end_time.strftime("%Y-%m-%d %H:%M:%S")#end_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")
   
   # prod_result_url = "http://103.114.208.206:3000/api/v1/equipment/product-results?from=#{stt_time}&&to=#{edd_time}"
   # resource_prod_result = RestClient::Resource.new(prod_result_url,'rabwin','yantra24x7')
   # response_prod_result = resource_prod_result.get
   # prod_result_data = JSON.parse response_prod_result.body

    machines.each do |key|
    puts key
    

   module_key= key.split("-").first

   if Shift.where(module: module_key).present?
   shift = Shift.current_shift2(module_key)
   else
   shift = Shift.current_shift2("GENERAL")
   end
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

   stt_time = start_time.strftime("%Y-%m-%d %H:%M:%S")#start_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")
   edd_time = end_time.strftime("%Y-%m-%d %H:%M:%S")#end_time.to_i#.utc#.strftime("%Y-%m-%dT%H:%M:%S:%z")

   prod_result_url = "http://103.114.208.206:3000/api/v1/equipment/product-results?from=#{stt_time}&&to=#{edd_time}"
   resource_prod_result = RestClient::Resource.new(prod_result_url,'rabwin','yantra24x7')
   response_prod_result = resource_prod_result.get
   prod_result_data = JSON.parse response_prod_result.body


    operate = []
    manual = []
    disconnect = []
    alarm = []
    emergency = []
    stop = []
    suspend = []
    warmup = []

    url_for_root_card = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/MacroVar_751_path1_#{key}/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_root_card = RestClient::Resource.new(url_for_root_card,'rabwin','yantra24x7')
    response_root_card = resource_root_card.get
    root_card_data = JSON.parse response_root_card.body   
    url_for_signal = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/condition/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_for_signal = RestClient::Resource.new(url_for_signal,'rabwin','yantra24x7')
    response_for_signal = resource_for_signal.get
    signal_data = JSON.parse response_for_signal.body 
    
   # http://103.114.208.206:3000/api/v1/equipment/VALVE-C46/monitorings/ProductResultNumber/logs?from=2021-08-15T00:00:00.000Z&&to=2021-08-20T00:00:00.000Z
  #  prod_result_url = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/ProductResultNumber/logs?from=#{stt_time}&&to=#{edd_time}"
  #  resource_prod_result = RestClient::Resource.new(prod_result_url,'rabwin','yantra24x7')
  #  response_prod_result = resource_prod_result.get
  #  prod_result_data = JSON.parse response_prod_result.body
    prod_result = prod_result_data.select{|kj| kj["equipmentName"] == key}

    if signal_data.count == 0
     signal_data >> {"start"=> start_time, "end"=> end_time, "value"=> "DISCONNECT"}
    elsif signal_data.count == 1
     signal_data.first["start"] = start_time
     signal_data.first["end"] = end_time
    else    
     signal_data.first['start'] = start_time
     signal_data.first['end'] = signal_data.first['end'].to_time.localtime
     signal_data.last['start'] = signal_data.last['start'].to_time.localtime
     signal_data.last['end'] = Time.now
    end
   # if key == "PUMP-C86"
   # byebug
   # end

    ##SS
      operator_id_1a = []
      route_card_1a = []
      operation_number_1a = []
      idle_reason_1a = []
      rejection_1a = []
      rework_1a = []


      if mac_sett[key].present?
       if mac_sett[key].first.signal.present?
       mac_sett[key].first.signal.each do |lis|
        case
         when lis.first[0] == "operator_id"
          operator_id_1a << lis.first[1]
         when lis.first[0] == "route_card"
          route_card_1a << lis.first[1]
         when lis.first[0] == "operation_number"
          operation_number_1a << lis.first[1]
         when lis.first[0] == "idle_reason"
          idle_reason_1a << lis.first[1]
         when lis.first[0] == "rejection"
          rejection_1a << lis.first[1]
         when lis.first[0] == "rework"
          rework_1a << lis.first[1]
         else
          puts "no"
         end
       end
        else
         operator_id_1a = [""]
         route_card_1a = [""]
         operation_number_1a = [""]
         idle_reason_1a = [""]
         rejection_1a = [""]
         rework_1a = [""]
        end
      else
      operator_id_1a = [""]
      route_card_1a = [""]
      operation_number_1a = [""]
      idle_reason_1a = [""]
      rejection_1a = [""]
      rework_1a = [""]
      end


    ##SSD



    signal_data.each do |data_convert|
     data_convert[:timespan] = (data_convert["end"].to_time - data_convert["start"].to_time).to_i
    end 
    
    group_split =  signal_data.group_by{|gg|gg["value"]}
    puts signal_data.pluck(:timespan).sum
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

     total_count_shift = prod_result.select{|sel| sel["end"].to_time.localtime > start_time && sel["start"].to_time.localtime < end_time && sel["end"].to_time.localtime < end_time && sel["increment"] != 0}.pluck("increment").sum

     tot_rejection = signal_data.select{|o| o["end"] > start_time && o["start"] < end_time && o['value'] == rejection_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
      
     tot_rework = signal_data.select{|o| o["end"] > start_time && o["start"] < end_time && o['value'] == rework_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum

     tot_idle = idle_time + alarm_time
     tot_idle_time = ((tot_idle*100)/duration)
     dis_or_bls = ((disconnect*100)/duration)
     
     time_wise_route_card = []
     if root_card_data.present?
      if root_card_data.count == 1
        root_card_data.first["start"] = start_time
        root_card_data.first["end"] = end_time
        root_card_data.first[:timespan] = (end_time - start_time).to_i
      else
        root_card_data.first["start"] = start_time
        root_card_data.first[:timespan] = (root_card_data.first["end"].to_time - start_time)
        root_card_data.last["end"] = end_time
        root_card_data.last[:timespan] = (end_time - root_card_data.last["start"].to_time)
      end
    
 
      root_card_data.each do |kvalue|
        if time_wise_route_card.count == 0
          if  kvalue["value"] != nil
          time_wise_route_card << kvalue
          end
        else
         if time_wise_route_card[-1]["value"] == kvalue["value"] || kvalue["value"] == nil || time_wise_route_card[-1]["value"] == nil || kvalue["value"] == 0.0
            time_wise_route_card << kvalue
          else
            time_wise_route_card << "##"
            time_wise_route_card << kvalue
          end
        end
      end
      end

     route_card_data = []     
     time_wise_route_list = []
     if time_wise_route_card.present?
       cumulate_data = time_wise_route_card.split("##")
       cumulate_data.each do |kk|
         comp_id = kk.pluck("value").compact.uniq.first
         st_time = kk.first["start"]
         en_time = kk.last["end"]
         time_wise_route_list << {comp_id: comp_id, st_time:st_time, ed_time: en_time}
        end
     end

     if time_wise_route_list.present?

       time_wise_route_list.each do |data|
        # production_result  = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < data[:ed_time].localtime && sel.productresult != 0}

       opr_list =  signal_data.select{|o| o["end"] > data[:st_time].to_time.localtime && o["start"] < data[:ed_time].to_time.localtime && data['value'] == operation_number_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}

        operator_name = []
        opr_list.each do |op_li|
          unless op_li.nan?
         if operators[op_li.to_i.to_s].present?
           operator_name << operators[op_li.to_i.to_s][0][1]
         else
           operator_name << "N/A"
         end
         else
           operator_name << "N/A"
         end
        end

           production_result = prod_result.select{|sel| sel["end"].to_time.localtime > data[:st_time].to_time.localtime && sel["start"].to_time.localtime < data[:ed_time].to_time.localtime && sel["end"].to_time.localtime < data[:ed_time].to_time.localtime && sel["increment"] != 0}
           if key ==  'VALVE-C109'
      byebug
      end

          if production_result.present?
           actual_produced =  production_result.pluck("increment").sum
           product_start_time = production_result.first["start"].to_time.localtime
           product_end_time = production_result.first["end"].to_time.localtime
           id_time_duration = []
           if start_time <= product_start_time
            cycle_time = signal_data.select{|jj| jj["end"] > product_start_time && jj["start"] < product_end_time  && jj["value"] == "OPERATE"}.pluck(:timespan).sum
           else
            cycles = []
            cycles << L1Pool.where(:enddate.gte => product_start_time, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
            cycles << L1Pool.where(:enddate.gte => product_start_time+1, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
            cyc_time = cycles.reject{|k| k==0}
            if cyc_time.empty?
             cycle_time = 0
            else
             cycle_time = cyc_time.min
            end
           end
           
           run_hr = data[:ed_time].to_time.localtime.to_i - data[:st_time].to_time.localtime.to_i
           if cycle_time == 0
            target = 0.0
            effe = 0.0
           else
            running_hour = (run_hr - (id_time_duration.sum))
            target = (running_hour/cycle_time).to_i
            if target.to_f == 0.0
              effe = 0
            else
              effe = (actual_produced.to_f/target.to_f)
            end
           end
           #start
           
           rejection = signal_data.select{|o| o["end"] > data[:st_time].to_time.localtime && o["start"] < data[:ed_time].to_time.localtime && data['value'] == rejection_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
           rework = signal_data.select{|o| o["end"] > data[:st_time].to_time.localtime && o["start"] < data[:ed_time].to_time.localtime && data['value'] == rework_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
#           rejection = signal_logs.select{|o| o.enddate > data[:st_time].localtime && o.updatedate < data[:ed_time].localtime && o.signalname == rejection_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
          # rework =  signal_logs.select{|w| w.enddate > data[:st_time].localtime && w.updatedate < data[:ed_time].localtime && w.signalname == rework_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i != 0}.sum 
       #   oper_id = signal_logs.select{|q| q.enddate > data[:st_time].localtime && q.updatedate < data[:ed_time].localtime && q.signalname == operation_number_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}
         # oper_id = signal_data.select{|o| o["end"] > data[:st_time].to_time.localtime && o["start"] < data[:ed_time].to_time.localtime && data['value'] == operation_number_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}

           float_value = data[:comp_id]%1
           if data[:comp_id] == 0
             mode = "No Entry"
           elsif float_value == 0
             mode = "Production"
           else
             mode = "Setting"
           end

           route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: effe*100, line: mac_lists[key].first[1], tar: target, actual: actual_produced, rout_start: data[:st_time].to_time.localtime, rout_end: data[:ed_time].to_time.localtime, rejection: rejection, rework: rework, opeation_no: [], operator_id: [], operator_name: []}
           #ss end
          else
           #NEWWWWWWWWWWWWWWWWWWWWWWW
             float_value = data[:comp_id]%1
             if data[:comp_id] == 0
              mode = "No Entry"
             elsif float_value == 0
              mode = "Production"
             else
              mode = "Setting"
             end
             route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: 0, rout_start: data[:st_time].to_time.localtime, rout_end: data[:ed_time].to_time.localtime, rejection: 0, rework: 0, opeation_no: [], operator_id: [], operator_name:[]}
          end
       end

     else
       #NEWWWWWWWWWWWWWWWWWWWWWWWWW
       route_card_data << {mode: "No Entry", card_no: "No Card", machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: total_count_shift, rout_start: start_time, rout_end: end_time, rejection: tot_rejection, rework: tot_rework, opeation_no: [], operator_id: [], operator_name: []}
     end



        total_route_entry = route_card_data.select{|u| u[:mode] == "Production" && u[:efficiency] != 0}
        if total_route_entry.present?
          m_tar =  total_route_entry.pluck(:tar).sum
          total_efficiency = total_route_entry.pluck(:efficiency).sum
          over_all_efficiency = (total_efficiency.to_f/total_route_entry.count)
        else
         m_tar = 0
         over_all_efficiency = 0
        end

     all_data << {
                  machine: key,
                  line: mac_lists[key].first[1],
                  tar: m_tar,
                  actual: total_count_shift,
                  efficiency: over_all_efficiency.to_i,
                  run: utilisation.to_i,
                  idle: tot_idle_time.to_i,
                  dis: dis_or_bls.to_i,
                  run_time: run_time,
                  idle_time: tot_idle,
                  discon_time: disconnect
                 }

    end
     if CurrentStatus.present?
    CurrentStatus.last.update(r_data: all_data, r_up_time: Time.now)
    else
     CurrentStatus.create(r_data: all_data, r_up_time: Time.now)
    end
    
   puts Time.now
  end
end
