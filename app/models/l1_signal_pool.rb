class L1SignalPool
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1Signal_Pool"

   field :L1Name, type: String
   field :updatedate, type: DateTime
   field :enddate, type: DateTime
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: Mongoid::Boolean
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String

   def self.report(date, shift_no)
  #  puts Time.now
    data = []
    oee_data = []
    shift = Shift.find_by(shift_no: shift_no)
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
    machines = L0Setting.pluck(:L0Name)
    key_list = []
    machines.each do |jj|
    key_list << "MacroVar_604_path1_#{jj}"
    end
  
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time)#.group_by{|kk| kk[:L1Name]}
    key_values = L1SignalPool.where(:signalname.in => key_list, :enddate.gte => start_time, :updatedate.lte => end_time, :enddate.lte => end_time) 
    key_value = L1SignalPoolActive.where(:signalname.in => key_list)
    components = Component.all

     final_data = []
     machines.each do |key|
      lastdata = key_value.select{|h| h.L1Name == key}
      all_data = key_values.select{|g| g.L1Name == key}
      
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
   #   else
      end
     

#      final_data = []
      compiled_component = []
      if tr_data.count == 1
      run_compinent = tr_data.first[:comp_id].to_i
      sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == key}
       if sel_comp.present?
        tar = sel_comp.first.target
        production_count = p_result.select{|sel| sel.enddate > tr_data.first[:st_time].localtime && sel.updatedate < tr_data.first[:ed_time].localtime && sel.L1Name == key && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum
        effe = production_count.to_f/tar.to_f
        effi = (effe * 100).to_i
        final_data << {machine: key, efficiency: effi}
       else
        final_data << {machine: key, efficiency: 0}
       end
      else
      
      tr_data.each do |data|
        run_compinent = data[:comp_id].to_i
        sel_comp = components.select{|u| u.spec_id == run_compinent && u.L0_name == key}
        if sel_comp.present?
         tar = sel_comp.first.target
         production_count = p_result.select{|sel| sel.enddate > data[:st_time].localtime && sel.updatedate < data[:ed_time].localtime && sel.L1Name == key && sel.enddate < tr_data.first[:ed_time] }.pluck(:productresult).sum
         sing_part_time = shift.actual_hour/tar
         run_hr = data[:ed_time].to_i - data[:st_time].to_i
         target = run_hr/sing_part_time
         effe = production_count.to_f/target.to_f
         effi = (effe * 100).to_i
         compiled_component << {machine: key, efficiency: effi}
        else
         compiled_component << {machine: key, efficiency: 0}
        end
      end
        if compiled_component.present?
        effi1 = compiled_component.pluck(:efficiency).sum/compiled_component.count
        final_data << {machine: key, efficiency: effi1}
        end
       
      end
     
     end
     byebug     
  end



















end
