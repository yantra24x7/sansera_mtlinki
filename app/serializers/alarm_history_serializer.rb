class AlarmHistorySerializer < ActiveModel::Serializer
  attributes :id, :L0Name, :L1Name, :enddate, :level, :message, :number, :time_span, :type, :updatedate
#  def start_time
#  object.updatedate.localtime
 # end
 # def end_time
 # object.enddate.localtime
 # end
  
  def time_span
  	Time.at(object.timespan).utc.strftime("%H:%M:%S") if object.timespan.present?
  end
end
