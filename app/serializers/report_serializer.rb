class ReportSerializer < ActiveModel::Serializer
  attributes :id, :date, :shift_num, :machine_name, :run_time, :idle_time, :alarm_time, :disconnect, :part_count, :part_name, :program_number, :duration, :utilisation, :shift_id, :target, :actual, :availability, :perfomance, :quality, :oee

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

  def target
      object.traget
  end
  
  def actual
    object.actual
  end
  
  def availability
    if object.availability.present?
    object.availability.round(2) * 100
    else
     0
    end
  end

  def perfomance
    if object.perfomance.present?
    object.perfomance.round(2) * 100
    else
     0
    end
  end
 
  def quality
   if object.quality.present?
   object.perfomance.round(2) * 100
   else
   0
   end
  end
  
  def oee
    if object.oee.present?
   (object.perfomance * object.quality * object.availability).round(2) * 100
    else
     0
    end
  end

end
