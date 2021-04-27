class L1PoolOpened
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1_Pool_Opened"

   field :L1Name, type: String
   field :updatedate, type: DateTime # Date
   field :enddate, type: DateTime # Date
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: String
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String

def self.insert_d
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    machines = mac_list.map{|i| [i[0], i[1].split('-').first]}

    key_list = []
    machines.each do |jj|
    key_list << "MacroVar_750_path1_#{jj[0]}"
    key_list << "MacroVar_751_path1_#{jj[0]}"
    key_list << "MacroVar_752_path1_#{jj[0]}"
    key_list << "MacroVar_753_path1_#{jj[0]}"
    key_list << "MacroVar_754_path1_#{jj[0]}"
    key_list << "MacroVar_755_path1_#{jj[0]}"
    key_list << "MacroVar_756_path1_#{jj[0]}"
    key_list << "MacroVar_757_path1_#{jj[0]}"

   tile =  L1SignalPool.where(L1Name: jj[0]).last.enddate.localtime
  
   a = L1SignalPoolCapped.where(:signalname.in=> key_list, :updatedate.gte => tile)
   a.each do |b|
     unless L1SignalPool.where(L1Name: b.L1Name, updatedate: b.updatedate, enddate: b.enddate, signalname: b.signalname).present?
    L1SignalPool.create(L1Name: b.L1Name, updatedate: b.updatedate, enddate: b.enddate, timespan: b.timespan, signalname: b.signalname, value: b.value)
    end
    end
    end

end




def self.j_c#(a,b)
    a = Date.yesterday.to_time 
    b = Time.now - 1.minutes    
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    machines = mac_list.map{|i| [i[0], i[1].split('-').first]}

    key_list = []
    machines.each do |jj|
    key_list << "MacroVar_750_path1_#{jj[0]}"
    key_list << "MacroVar_751_path1_#{jj[0]}"
    key_list << "MacroVar_752_path1_#{jj[0]}"
    key_list << "MacroVar_753_path1_#{jj[0]}"
    key_list << "MacroVar_754_path1_#{jj[0]}"
    key_list << "MacroVar_755_path1_#{jj[0]}"
    key_list << "MacroVar_756_path1_#{jj[0]}"
    key_list << "MacroVar_757_path1_#{jj[0]}"
    end
key_lists = L1SignalPoolActive.pluck(:signalname).uniq

als = key_lists - key_list
data = L1SignalPool.where(:enddate.gte => a, :updatedate.lte => b, :signalname.in=> als)#.delete_all
puts data.count
data.delete_all

end


def self.cron_delay
  date = Date.today.to_s
 # date = Date.yesterday.to_s
 # date = "2021-04-10"
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
     Report.delay(run_at: end_time + 2.minutes).general_report(date, shift.shift_no)
   end
   
   unless Delayed::Job.where(run_at: end_time + 3.minutes).present?
     IdleReasonActive.delay(run_at: end_time + 3.minutes).idle_reason_report(date, shift.shift_no)
   end
  end
end



end
