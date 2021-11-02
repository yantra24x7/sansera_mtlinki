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
  field :module, type: String
  # belongs_to :OperatorAllocation
  has_many :reports

  validates :start_time, :end_time, :total_hour, :shift_no, :start_day, :end_day, :break_time, :module, presence: true

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

  def self.current_shift2(module_key)
    shift = []
    shifts = Shift.where(module: module_key)
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



    def self.general_report(date, shift_no, module1)
#   puts Time.now
    data = []
    oee_data = []
  
  #  byebug

    shift = Shift.find_by(shift_no:shift_no, module: module1)
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
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[0]}
 
    machines = []  
    mac_lists.keys.each do |jj|
     if jj.include?(module1)
     machines << jj 
     end
    end

    mac_sett = MachineSetting.where(group_signal: "MacroVar").group_by{|d| d[:L1Name]}
    mac_sett2 = MachineSetting.where(group_signal: "MacroVar")
    if mac_sett2.present?
     macro_list = mac_sett2.map{|i| i.signal}.flatten.map{|j| j.first[1]}
    else
     macro_list = []
    end
    
    stt_time = start_time.strftime("%Y-%m-%d %H:%M:%S")
    edd_time = end_time.strftime("%Y-%m-%d %H:%M:%S")

    prod_result_url = "http://103.114.208.206:3000/api/v1/equipment/product-results?from=#{stt_time}&&to=#{edd_time}"
    resource_prod_result = RestClient::Resource.new(prod_result_url,'rabwin','yantra24x7')
    response_prod_result = resource_prod_result.get
    prod_result_data = JSON.parse response_prod_result.body

    operators = Operator.all.pluck(:operator_spec_id, :operator_name).group_by(&:first)

 
  machines.each do |key|
     puts key
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

    url_for_operator_id = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/MacroVar_750_path1_#{key}/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_operator_id = RestClient::Resource.new(url_for_operator_id,'rabwin','yantra24x7')
    response_operator_id = resource_operator_id.get
    res_operator_id = JSON.parse response_operator_id.body
    
    if res_operator_id.present?
     if res_operator_id.last['end'] == nil
       res_operator_id.last['end'] = end_time
     end
    end

    url_for_opr_num = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/MacroVar_752_path1_#{key}/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_opr_num = RestClient::Resource.new(url_for_opr_num,'rabwin','yantra24x7')
    response_opr_num = resource_opr_num.get
    res_opr_num = JSON.parse response_opr_num.body
  
    if res_opr_num.present?
     if res_opr_num.last['end'] == nil
       res_opr_num.last['end'] = end_time
     end
    end


    url_for_rejection = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/MacroVar_756_path1_#{key}/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_rejection = RestClient::Resource.new(url_for_rejection,'rabwin','yantra24x7')
    response_rejection = resource_rejection.get
    res_rejection = JSON.parse response_rejection.body
   
    if res_rejection.present?
     if res_rejection.last['end'] == nil
       res_rejection.last['end'] = end_time
     end
    end
   
    url_for_rework = "http://103.114.208.206:3000/api/v1/equipment/#{key}/monitorings/MacroVar_757_path1_#{key}/logs?from=#{stt_time}&&to=#{edd_time}"
    resource_rework = RestClient::Resource.new(url_for_rework,'rabwin','yantra24x7')
    response_rework = resource_rework.get
    res_rework = JSON.parse response_rework.body
    
    if res_rework.present?
     if res_rework.last['end'] == nil
       res_rework.last['end'] = end_time
     end
    end


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
     signal_data.last['end'] = end_time
    end


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

     tot_rejection = res_rejection.select{|o| o["end"].to_time.localtime > start_time && o["start"].to_time.localtime < end_time}.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum

     tot_rework = res_rework.select{|o| o["end"].to_time.localtime > start_time && o["start"].to_time.localtime < end_time }.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum

     tot_oper_id = res_opr_num.select{|q| q["end"].to_time.localtime > start_time && q["start"].to_time.localtime < end_time}.pluck("value").uniq.select{|i| i!=nil && i!= 0}

     tot_operator_id = res_operator_id.select{|q| q["end"].to_time.localtime > start_time && q["start"].to_time.localtime < end_time}.pluck("value").uniq.select{|i| i!=nil && i!= 0}#.reject! &:nan?

     opr_lists = tot_operator_id#.map(&:to_i)
     operator_names = []

     opr_lists.each do |op_li|
    
#     unless op_li.nan?
      if operators[op_li.to_i.to_s].present?
       operator_names << operators[op_li.to_i.to_s][0][1]
      else
       operator_names << "N/A"
      end
#     else
#      operator_names << "N/A"
     end
#     end

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

    
    



     chart_data = []
 
     part_result_data = prod_result.select{|sel| sel["end"].to_time.localtime > start_time && sel["start"].to_time.localtime < end_time && sel["end"].to_time.localtime < end_time && sel["increment"] != 0}
    
     part_result_data.each do |part_ind|

      if part_ind["start"].to_time.localtime < start_time

        parts_signal_data = L1Pool.where(:updatedate.gte => part_ind['start'].to_time.localtime, L1Name: key, :enddate.lte => part_ind['end'].to_time.localtime)
        single_part_filter = parts_signal_data.select{|hh| hh.updatedate >= part_ind['start'].to_time.localtime && hh.value == "OPERATE"}
        if single_part_filter.present?
           chart_data << {load_start: part_ind['start'].to_time.localtime, load_end:single_part_filter.first.updatedate.localtime , cycle_start: single_part_filter.first.updatedate.localtime, cycle_end: part_ind['end'].to_time.localtime, operate: true}
        else
           chart_data << {load_start: part_ind['start'].to_time.localtime, load_end:part_ind['end'].to_time.localtime, cycle_start: part_ind['start'].to_time.localtime, cycle_end: part_ind['end'].to_time.localtime, operate: false}
        end
      else
       single_part_filter = signal_data.select{|m| m['start'].to_time.localtime >= part_ind['start'].to_time.localtime && m['end'].to_time.localtime <= part_ind['end'].to_time.localtime && m['value'] == "OPERATE"}

       if single_part_filter.present?
           chart_data << {load_start: part_ind['start'].to_time.localtime, load_end:single_part_filter.first['start'].to_time.localtime , cycle_start: single_part_filter.first['start'].to_time.localtime, cycle_end: part_ind['end'].to_time.localtime, operate: true}
        else
           chart_data << {load_start: part_ind['start'].to_time.localtime, load_end: part_ind['end'].to_time.localtime, cycle_start:  part_ind['start'].to_time.localtime, cycle_end: part_ind['end'].to_time.localtime, operate: false}
        end
      end
     end

company = "RABWIN"

 if time_wise_route_list.present?
   time_wise_route_list.each do |data|
       opr_list =  res_operator_id.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime}.pluck("value").uniq.select{|i| i!=nil && i!= 0}

      #NEW
           rejection = res_rejection.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime}.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum
           rework = res_rework.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime }.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum
          oper_num = res_opr_num.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime}.pluck("value").uniq.select{|i| i!=nil && i!= 0}
      #NEW


        operator_name = []
        opr_list.each do |op_li|
#          unless op_li.nan?
         if operators[op_li.to_i.to_s].present?
           operator_name << operators[op_li.to_i.to_s][0][1]
         else
           operator_name << "N/A"
         end
 #        else
 #          operator_name << "N/A"
 #        end
        end
  
           production_result = prod_result.select{|sel| sel["end"].to_time.localtime > data[:st_time].to_time.localtime && sel["start"].to_time.localtime < data[:ed_time].to_time.localtime && sel["end"].to_time.localtime < data[:ed_time].to_time.localtime && sel["increment"] != 0}
          
          # if company == "RABWIN"
           if production_result.present?
           if company == "RABWIN"
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
           else#COMPANY
             #SANSERA CODE
           end
           #start
    #       rejection = res_rejection.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime}.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum
    #       rework = res_rework.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime }.pluck("value").uniq.select{|i| i!=nil && i!= 0}.sum
    #      oper_num = res_opr_num.select{|o| o["end"].to_time.localtime > data[:st_time].to_time.localtime && o["start"].to_time.localtime < data[:ed_time].to_time.localtime}.pluck("value").uniq.select{|i| i!=nil && i!= 0}
           
           float_value = data[:comp_id]%1
           if data[:comp_id] == 0
             mode = "No Entry"
           elsif float_value == 0
             mode = "Production"
           else
             mode = "Setting"
           end

           route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: (effe*100).round(2), line: mac_lists[key].first[1], tar: target, actual: actual_produced, rout_start: data[:st_time].to_time.localtime, rout_end: data[:ed_time].to_time.localtime, rejection: rejection, rework: rework, opeation_no: oper_num, operator_id: opr_list, operator_name: operator_name, rejection1: 0}
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
           route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: 0, rout_start: data[:st_time].to_time.localtime, rout_end: data[:ed_time].to_time.localtime, rejection: 0, rework: 0, opeation_no: oper_num, operator_id: opr_list, operator_name: operator_name,rejection1: 0} 
         end
       end

     else
       #NEWWWWWWWWWWWWWWWWWWWWWWWWW
     route_card_data << {mode: "No Entry", card_no: "No Card", machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: total_count_shift, rout_start: start_time, rout_end: end_time, rejection: tot_rejection, rework: tot_rework, opeation_no: tot_oper_id, operator_id: opr_lists, operator_name: operator_names, rejection1: 0}   
  end





 # -- test code -- #
 #     operator_id_1a = []
 #     route_card_1a = []
 #     operation_number_1a = []
 #     idle_reason_1a = []
 #     rejection_1a = []
 #     rework_1a = []


 #     if mac_sett[key].present?
 #      if mac_sett[key].first.signal.present?
 #      mac_sett[key].first.signal.each do |lis|
 #       case
 #        when lis.first[0] == "operator_id"
 #         operator_id_1a << lis.first[1]
 #        when lis.first[0] == "route_card"
 #         route_card_1a << lis.first[1]
 #        when lis.first[0] == "operation_number"
 #         operation_number_1a << lis.first[1]
 #        when lis.first[0] == "idle_reason"
 #         idle_reason_1a << lis.first[1]
 #        when lis.first[0] == "rejection"
 #         rejection_1a << lis.first[1]
 #        when lis.first[0] == "rework"
 #         rework_1a << lis.first[1]
 #        else
 #         puts "no"
 #        end
 #      end
 #       else
 #        operator_id_1a = [""]
 #     route_card_1a = [""]
 #     operation_number_1a = [""]
 #     idle_reason_1a = [""]
 #     rejection_1a = [""]
 #     rework_1a = [""]

 #       end
 #            else
 #     operator_id_1a = [""]
 #     route_card_1a = [""]
 #     operation_number_1a = [""]
 #     idle_reason_1a = [""]
 #     rejection_1a = [""]
 #    rework_1a = [""]

 #     end
  
 
#     tot_rejection = signal_logs.select{|o| o.enddate > start_time && o.updatedate < end_time && o.signalname == rejection_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
#     tot_rework =  signal_logs.select{|w| w.enddate > start_time && w.updatedate < end_time && w.signalname == rework_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i != 0}.sum
#     tot_oper_id = signal_logs.select{|q| q.enddate > start_time && q.updatedate < end_time && q.signalname == operation_number_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}
#     tot_operator_id = signal_logs.select{|q| q.enddate > start_time && q.updatedate < end_time && q.signalname == operator_id_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}#.reject! &:nan?

  #  if tot_operator_id.include? Float::NAN
  #  tot_operator_id_lis = tot_operator_id.reject! &:nan?
  #  else
  #  tot_operator_id_lis = []
  #  end


  #   if key == 'PUMP-C86'

  #   end

 #    opr_lists = tot_operator_id#.map(&:to_i)
 #    operator_names = []
 #    opr_lists.each do |op_li|
 #    unless op_li.nan?
 #     if operators[op_li.to_i.to_s].present?
 #      operator_names << operators[op_li.to_i.to_s][0][1]
 #     else
 #      operator_names << "N/A"
 #     end
 #    else
 #     operator_names << "N/A"
 #    end
 #    end


    # ---- Route Card ---- #
    # MacroVar_751_path1_#{key}
#     route_card_data = []
#     route_logs = signal_logs.select{|g| g.L1Name == key && g.signalname == route_card_1a.first}
#     route_log = signal_log.select{|f| f.L1Name == key && f.signalname == route_card_1a.first }
     # ----- Idle Reason ---- #
#     idle_reason_data = []
#     idle_logs = signal_logs.select{|g| g.L1Name == key && g.signalname == idle_reason_1a}
   #  idle_log = signal_log.select{|f| f.L1Name == key && f.signalname == "MacroVar_755_path1_#{key}"}

   #  if idle_log.present?
   #   if [start_time..end_time].include?(idle_log.first.updatedate) || idle_log.first.updatedate <= start_time
   #     idle_log.first[:enddate] = end_time.utc
   #     route_logs << route_log.first
   #   end
   #  end


#     if route_log.present?
#      if [start_time..end_time].include?(route_log.first.updatedate) || route_log.first.updatedate <= start_time
#        route_log.first[:enddate] = (((end_time - 1) + 1).utc).to_time
#        route_logs << route_log.first
#      end
#     end

#     time_wise_route_card = []
#     if route_logs.present?
#      if route_logs.count == 1
#        route_logs.first[:updatedate] = start_time
#        route_logs.first[:enddate] = end_time
#        route_logs.first[:timespan] = (end_time - start_time).to_i
#      else
#        route_logs.first[:updatedate] = start_time
#        route_logs.first[:timespan] = (route_logs.first.enddate.to_time - start_time)
#        route_logs.last[:enddate] = end_time
#        route_logs.last[:timespan] = (end_time - route_logs.last.updatedate.to_time)
#      end

#         route_logs.each do |kvalue|
#        if time_wise_route_card.count == 0
#          if  kvalue.value != nil
#          time_wise_route_card << kvalue
#          end
#        else
#          if time_wise_route_card[-1].value == kvalue.value || kvalue.value == nil || time_wise_route_card[-1].value == nil || kvalue.value == 0.0
#            time_wise_route_card << kvalue
#          else
#            time_wise_route_card << "##"
#            time_wise_route_card << kvalue
#          end
#        end
#      end
#     end

#     time_wise_route_list = []
#     if time_wise_route_card.present?
#       cumulate_data = time_wise_route_card.split("##")
#       cumulate_data.each do |kk|
#         comp_id = kk.pluck(:value).compact.uniq.first
#         st_time = kk.first.updatedate
#         en_time = kk.last.enddate
#         time_wise_route_list << {comp_id: comp_id, st_time:st_time, ed_time: en_time}
#        end
#     end
#         if time_wise_route_list.present?
#       time_wise_route_list.each do |data|
#         production_result  = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < data[:ed_time].localtime && sel.productresult != 0}

#         opr_list = signal_logs.select{|o| o.enddate > data[:st_time].localtime && o.updatedate < data[:ed_time].localtime && o.signalname == operator_id_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}#.map(&:to_i)

#        operator_name = []
#        opr_list.each do |op_li|
#          unless op_li.nan?
#         if operators[op_li.to_i.to_s].present?
#           operator_name << operators[op_li.to_i.to_s][0][1]
#         else
#           operator_name << "N/A"
#         end
#         else
#           operator_name << "N/A"
#         end
#        end

#         if production_result.present?
#           actual_produced =  production_result.pluck(:productresult).sum
#           product_start_time = production_result.first.updatedate.localtime
#           product_end_time = production_result.first.enddate.localtime
#           id_time_duration = []
#           if idle_logs.present?
#             ac = idle_logs.reject{|kk| kk.value == 0}
#             ac_data = ac.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime}
#             if ac_data.present?
#               unless ac_data.first.updatedate > data[:st_time].localtime
#                ac_data.first.updatedate = data[:st_time]
#               end
#               if ac_data.first.enddate > data[:ed_time].localtime
#                ac_data.first.enddate = data[:ed_time]
#               end
#               ac_data.each do |dd|
#                id_time_duration << (dd.enddate.to_i - dd.updatedate.to_i).to_f
#               end
#             end
#           else
#           end
#                if start_time <= product_start_time
#            cycle_time = value.select{|jj| jj.enddate > product_start_time && jj.updatedate < product_end_time  && jj.value == "OPERATE"}.pluck(:timespan).sum
#           else
#            cycles = []
#            cycles << L1Pool.where(:enddate.gte => product_start_time, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
#            cycles << L1Pool.where(:enddate.gte => product_start_time+1, :updatedate.lte => product_end_time, :enddate.lte => product_end_time, :L1Name=> key, value: "OPERATE").pluck(:timespan).sum
#            cyc_time = cycles.reject{|k| k==0}
#            if cyc_time.empty?
#             cycle_time = 0
#            else
#             cycle_time = cyc_time.min
#            end
#           end
#           run_hr = data[:ed_time].to_i - data[:st_time].to_i
#           if cycle_time == 0
#            target = 0.0
#            effe = 0.0
#           else
#            running_hour = (run_hr - (id_time_duration.sum))
#            target = (running_hour/cycle_time).to_i
#            if target.to_f == 0.0
#              effe = 0
#            else
#              effe = (actual_produced.to_f/target.to_f)
#            end
#           end
#           rejection = signal_logs.select{|o| o.enddate > data[:st_time].localtime && o.updatedate < data[:ed_time].localtime && o.signalname == rejection_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}.sum
#           rework =  signal_logs.select{|w| w.enddate > data[:st_time].localtime && w.updatedate < data[:ed_time].localtime && w.signalname == rework_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i != 0}.sum
#           oper_id = signal_logs.select{|q| q.enddate > data[:st_time].localtime && q.updatedate < data[:ed_time].localtime && q.signalname == operation_number_1a.first}.pluck(:value).uniq.select{|i| i!=nil && i!= 0}

#           float_value = data[:comp_id]%1
#           if data[:comp_id] == 0
#             mode = "No Entry"
#           elsif float_value == 0
#             mode = "Production"
#           else
#             mode = "Setting"
#           end

#           route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: (effe*100).round(2), line: mac_lists[key].first[1], tar: target, actual: actual_produced, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime, rejection: rejection, rework: rework, opeation_no: oper_id, operator_id: opr_list, operator_name: operator_name, rejection1: 0}

#         else
#          float_value = data[:comp_id]%1
#          if data[:comp_id] == 0
#           mode = "No Entry"
#          elsif float_value == 0
#           mode = "Production"
#          else
#           mode = "Setting"
#          end

#          route_card_data << {mode: mode, card_no: data[:comp_id].to_i, machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: 0, rout_start: data[:st_time].localtime, rout_end: data[:ed_time].localtime, rejection: 0, rework: 0, opeation_no: [], operator_id: opr_list, operator_name: operator_name,rejection1: 0}
#         end
#       end
#     else
#      route_card_data << {mode: "No Entry", card_no: "No Card", machine: key, efficiency: 0, line: mac_lists[key].first[1], tar: 0, actual: total_count_shift, rout_start: start_time, rout_end: end_time, rejection: tot_rejection, rework: tot_rework, opeation_no: tot_oper_id, operator_id: opr_lists, operator_name: operator_names, rejection1: 0}
#     end

    # ---- Route Card End  ---- #

    # ---- Cycle Time Start ---- #

    # ---- Cycle Time End ---- #

    # ---- Calculation Start ---- #

     total_count = route_card_data.pluck(:actual).sum
     total_target = route_card_data.pluck(:tar).sum
     total_route_entry = route_card_data.select{|u| u[:mode] != "No Entry" && u[:mode] != "Setting" && u[:efficiency] != 0}

     if total_route_entry.present?
      total_efficiency = total_route_entry.pluck(:efficiency).sum
      total_rejection = total_route_entry.pluck(:rejection).sum
      total_rework = total_route_entry.pluck(:rework).sum
      total_actual = total_route_entry.pluck(:actual).sum
      total_tar = total_route_entry.pluck(:tar).sum

      over_all_efficiency = (total_efficiency.to_f/total_route_entry.count)
      total_wasted_part = (total_rejection + total_rework)

      if total_actual != 0 && total_actual > total_wasted_part
       good_part = total_actual - total_wasted_part
       quality = (good_part/total_actual)
      else
       quality = 0
      end
     else
      over_all_efficiency = 0
      quality = 0
     end


    planed_production_time = duration - shift.break_time
    availability = (run_time/planed_production_time.to_f)
  #  t_availability = availability * 100
  #  t_quality = quality * 100
  #  t_perfomance = over_all_efficiency * 100
  #  oee = (availability * over_all_efficiency * quality) * 100
     data <<
      {
      date: date,
      shift_num: shift.shift_no,
      time: start_time.strftime("%H:%M:%S")+' - '+end_time.strftime("%H:%M:%S"),
      shift_id: shift.id,
      machine_name: key,
      line: mac_lists[key].first[1],
      run_time: run_time,
      idle_time: idle_time,
      alarm_time: alarm_time,
      disconnect: disconnect,
      part_count: total_count_shift,
      part_name: nil,
      program_number: nil,
      component_id: time_wise_route_list.pluck(:comp_id),
      duration: duration,
      utilisation: utilisation,
      target: total_target,
      actual: total_count,
      efficiency: over_all_efficiency,

      availability: availability,
      perfomance: 0,
      quality: 0,
      oee: 0,

      operator: operator_names,
      operator_id: opr_lists,
      route_card_report: route_card_data,
      chart_data: chart_data
      }

    end
      data.each do |data1|

      unless Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).present?

        report = Report.create(time: data1[:time], date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee], target: data1[:target], actual: data1[:actual], efficiency: data1[:efficiency], line: data1[:line], component_id: data1[:component_id], operator: data1[:operator], operator_id: data1[:operator_id], route_card_report: data1[:route_card_report], chart_data: data1[:chart_data])
       else
        report = Report.where(date: data1[:date], shift_num: data1[:shift_num], machine_name:data1[:machine_name]).last

        report.update(time: data1[:time], run_time:data1[:run_time], idle_time: data1[:idle_time], disconnect: data1[:disconnect], part_count: data1[:part_count], part_name: data1[:part_name], program_number: data1[:program_number], shift_id: data1[:shift_id], duration: data1[:duration], utilisation: data1[:utilisation], oee_data: data1[:oee], alarm_time: data1[:alarm_time], availability: data1[:availability], perfomance: data1[:perfomance], quality:data1[:quality], oee: data1[:oee],target: data1[:target], actual: data1[:actual],efficiency: data1[:efficiency], line: data1[:line], component_id: data1[:component_id], operator: data1[:operator], operator_id: data1[:operator_id], route_card_report: data1[:route_card_report], chart_data: data1[:chart_data])
      end
    end

  end
end
