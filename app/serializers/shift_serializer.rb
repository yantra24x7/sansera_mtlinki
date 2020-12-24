class ShiftSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time,:shift_no, :start_day, :end_day, :duration, :total_hour, :break_time, :actual_hour
  
  def duration
    case
    when object.start_day == '1' && object.end_day == '1'
     duratiotn = Time.at(object.end_time.to_time - object.start_time.to_time).utc.strftime("%H:%M:%S")
    when object.start_day == '1' && object.end_day == '2'
     duration = Time.at((object.end_time.to_time+1.day) - object.start_time.to_time).utc.strftime("%H:%M:%S")
    else
     duration = Time.at(object.end_time.to_time - object.start_time.to_time).utc.strftime("%H:%M:%S")
    end

  end
  def break_time
    Time.at(object.break_time).utc.strftime("%H:%M:%S")
  end
  def total_hour
    Time.at((object.total_hour).to_i).utc.strftime("%H:%M:%S")
  end
  def actual_hour
    Time.at(object.actual_hour).utc.strftime("%H:%M:%S")
  end
 
end
