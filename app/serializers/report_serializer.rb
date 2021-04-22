class ReportSerializer < ActiveModel::Serializer
  attributes :id, :time, :date, :shift_num, :machine_name, :run_time, :idle_time, :alarm_time, :disconnect, :part_count, :part_name, :program_number, :duration, :utilisation, :shift_id, :target, :actual, :availability, :perfomance, :quality, :oee, :line, :operator, :operator_id, :root_card, :efficiency, :route_card_report, :accept, :reject, :rework, :edit_reason
  def route_card_report
   object.route_card_report.each do |res|
     act = res["actual"]
     wat = res["rejection"] + res["rework"]
     res[:accept] = act - wat
   end
  end 
  def root_card
   if object.component_id == nil
    []
   else
   object.component_id.uniq
   end
  end
  
  def operator_id
   if object.operator_id == nil
    []
   else
   object.operator_id.uniq
   end
  end

  def operator
   if object.operator == nil
    []
   else
   object.operator.uniq
   end
  end

  def duration
  	Time.at(object.duration).utc.strftime("%H:%M:%S") if object.duration.present?
  end
  def run_time
  	Time.at((object.run_time).to_i).utc.strftime("%H:%M:%S") if object.run_time.present?
  end
  def alarm_time
    Time.at((object.alarm_time).to_i).utc.strftime("%H:%M:%S") if object.alarm_time.present?
  end
  def idle_time
  	Time.at((object.idle_time).to_i).utc.strftime("%H:%M:%S") if object.idle_time.present?
  end
  def disconnect
   	Time.at((object.disconnect).to_i).utc.strftime("%H:%M:%S") if object.disconnect.present?
  end

#  def target
#      object.traget
#  end
  
  def actual
    object.actual
  end
  
  def availability
    if object.availability.present?
    (object.availability * 100).round(2)
    else
     0
    end
  end

  def perfomance
    if object.route_card_report.present?
     total_route_entry = object.route_card_report.select{|u| u[:mode] != "No Entry" && u[:mode] != "Setting" && u[:efficiency] != 0}
     if total_route_entry.pluck(:efficiency).sum != 0 && total_route_entry.count != 0
     @per = (total_route_entry.pluck(:efficiency).sum / total_route_entry.count).round(2)/100 
     @perfomance = (total_route_entry.pluck(:efficiency).sum / total_route_entry.count).round(2)
     else
     @per = 0
     end
    else
     @per = 0
    end
  end
 
  def quality

   if object.route_card_report.present?
    total_route_entry = object.route_card_report.select{|u| u[:mode] != "No Entry" && u[:mode] != "Setting" && u[:efficiency] != 0}
   @rej = total_route_entry.pluck(:rejection).sum 
   @rewo = total_route_entry.pluck(:rework).sum
    @total_actual = total_route_entry.pluck(:actual).sum
    total_wasted_part = @rewo + @rej
         
      if @total_actual != 0 && @total_actual > total_wasted_part
       @good_part = @total_actual - total_wasted_part
       @qul = (@good_part.to_f/@total_actual.to_f)
       quality = ((@good_part.to_f/@total_actual.to_f) * 100).round(2)
      else
       @good_part = 0
       @qul = 0
       quality = 0
      end
#   (object.quality* 100).round(2)
   else
    @good_part = 0
    @rej = 0
    @rewo = 0
    @total_actual = 0
    @qul = 0
   end
  end
  
  def oee
   oee = ((object.availability * @per * @qul)*100).round(2)
  end
  
  def accept
   @good_part
  end
  def reject
   @rej
  end
  def rework
   @rewo
  end

  def edit_reason
   if object.edit_reason == nil
    []
   else
    []
   end
  end
end
