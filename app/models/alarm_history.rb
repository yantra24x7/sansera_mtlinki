class AlarmHistory
   include Mongoid::Document
   include Mongoid::Search
   # include Mongoid::Timestamps
   store_in collection: "Alarm_History"

   field :L1Name, type: String
   field :L0Name, type: String
   field :number, type: String
   field :updatedate, type: DateTime # Date
   field :message, type: String
   field :enddate, type: DateTime # Date
   field :level, type: Integer
   field :type, type: String
   field :timespan, type: Float #Integeri
   
   search_in :L0Name, :message, :updatedate, :enddate
  # search_in :message, index: :_unit_keywords

end
