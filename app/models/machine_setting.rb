class MachineSetting
  include Mongoid::Document
  include Mongoid::Timestamps
  field :L1Name, type: String
  field :group_signal, type: String
  field :signal, type: Array
  field :value, type: Array
  field :min, type: Integer
  field :max, type: Integer
def self.setting(params)
  value = []
  unless MachineSetting.where(group_signal: "SpindleLoad", L1Name: params[:L1Name]).present?
   val = MachineSetting.create(L1Name: params[:L1Name], group_signal: "SpindleLoad", signal: [], value: ["SpindleLoad_0_path1_#{params[:L1Name]}"], max: 150)
   value << val
  else
   val = MachineSetting.where(group_signal: "SpindleLoad", L1Name: params[:L1Name]).first
   value << val
  end
 list_of_setting = ["ServoLoad"]
 axis_list = [{x_axis: false, y_axis: false, z_axis: false, a_axis: false, b_axis: false}]
# ServoLoad_0_path1_PUMP-C86
 list_of_setting.each do |list_of_sett|
  signal = []
  axis_list.first.each do |k, v|
   case 
   when k == :x_axis 
    val = 0
   when k == :y_axis
    val = 1
   when k == :z_axis
    val = 2
   when k == :a_axis
    val = 3
   when k == :b_axis
    val = 4
   end
    signal << "#{list_of_sett}_#{val}_path1_#{params[:L1Name]}"
   end
  unless MachineSetting.where(group_signal: list_of_sett, L1Name: params[:L1Name]).present?
   val = MachineSetting.create(L1Name: params[:L1Name], group_signal: list_of_sett, signal: axis_list, value: signal)
   value << val 
  else
    val = MachineSetting.where(group_signal: list_of_sett, L1Name: params[:L1Name]).first
    value << val
  end
 end
  return value
end

def self.macro_setting(params)
 value = []
 macro = "MacroVar"
 list1 = []
 if params[:operator_id].present?
  list1 << {operator_id: "#{macro}_#{params[:operator_id]}_path1_#{params[:L1Name]}"} 
 end
 
 if params[:route_card].present?
  list1 << {route_card: "#{macro}_#{params[:route_card]}_path1_#{params[:L1Name]}"}
 end

 if params[:operation_number].present?
   list1 << {operation_number: "#{macro}_#{params[:operation_number]}_path1_#{params[:L1Name]}"}
 end

 if params[:idle_reason].present?
   list1 << {idle_reason: "#{macro}_#{params[:idle_reason]}_path1_#{params[:L1Name]}"}
 end

 if params[:rejection].present?
  list1 << {rejection: "#{macro}_#{params[:rejection]}_path1_#{params[:L1Name]}"}
 end

 if params[:rework].present?
  list1 << {rework: "#{macro}_#{params[:rework]}_path1_#{params[:L1Name]}"}
 end



 fin_list = []
 list1.each do |k,v|
  fin_list << k.first[1]
 end
  unless MachineSetting.where(L1Name: params[:L1Name], group_signal: macro).present?
   val = MachineSetting.create(L1Name: params[:L1Name], group_signal: macro, signal: list1, value: fin_list)

    data1 = []
        val.signal.each do |key, value|
         op = key.keys.first
         data1 << {op=> key.values.first.split('_').second.to_i}
        end

  else
    val = MachineSetting.where(L1Name: params[:L1Name], group_signal: macro).first
   
     data1 = []
        val.signal.each do |key, value|
         op = key.keys.first
         data1 << {op=> key.values.first.split('_').second.to_i}
        end
  end
  return data1
end
end
