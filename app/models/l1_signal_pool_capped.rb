class L1SignalPoolCapped
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1Signal_Pool_Capped"

   field :L1Name, type: String
   field :updatedate, type: DateTime
   field :enddate, type: DateTime
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: Mongoid::Boolean
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String

end