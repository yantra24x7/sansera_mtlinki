class ShiftSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :total_hour, :shift_no, :start_day, :end_day, :duration
  
  def duration
    case
    when object.start_day == '1' && object.end_day == '1'
     duration = object.end_time.to_time - object.start_time.to_time
    when object.start_day == '1' && object.end_day == '2'
     duration = (object.end_time.to_time+1.day) - object.start_time.to_time
    else
     duration = object.end_time.to_time - object.start_time.to_time
    end

  end
 
end
