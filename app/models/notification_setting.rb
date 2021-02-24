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



 def self.report(date, shift_no)
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
    duration = (end_time - start_time).to_i
    #machines = L0Setting.pluck(:L0Name)
    mac_list = L0Setting.pluck(:L0Name, :L0EnName)
    mac_lists = mac_list.map{|i| [i[0], i[1].split('-').first]}.group_by{|yy| yy[0]}


    key_list = []
    mac_lists.keys.each do |jj|
    key_list << "MacroVar_750_path1_#{jj}"
    key_list << "MacroVar_751_path1_#{jj}"
    key_list << "MacroVar_752_path1_#{jj}"
    key_list << "MacroVar_753_path1_#{jj}"
    key_list << "MacroVar_754_path1_#{jj}"
    key_list << "MacroVar_755_path1_#{jj}"
    key_list << "MacroVar_756_path1_#{jj}"
    key_list << "MacroVar_758_path1_#{jj}"
    end
byebug

 end



 
end
