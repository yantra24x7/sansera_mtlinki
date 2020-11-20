class L1SignalPoolActive
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1Signal_Pool_Active"

   field :L1Name, type: String
   field :updatedate, type: DateTime # Date
   field :enddate, type: DateTime # Date
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: Mongoid::Boolean
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String
end