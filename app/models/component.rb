class Component
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :spec_id, type: Integer
  field :program_number, type: String
  field :cycle_time, type: Integer
  field :target, type: Integer
  field :multiplication_factor, type: Integer
  field :is_active, type: Mongoid::Boolean
  field :L0_name, type: String
#  belongs_to :l0_setting
 
  index({L0_name: 1, L0Setting_id: 1, spec_id: 1})    
  index({L0_name: 1, spec_id: 1})

 # validates :name, :spec_id, uniqueness: true
  validates :name, :spec_id, :L0_name, :cycle_time, :target, :multiplication_factor, presence: true  


 def self.report(date, shift_no)
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
    
    machines.each do |mac|
     card_trans = key_values.select{|ii| ii.L1Name == mac}
     card_tran = key_value.select{|jj| jj.L1Name == mac }
     byebug
    end

 end





end
