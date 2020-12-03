class L1PoolOpened
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L1_Pool_Opened"

   field :L1Name, type: String
   field :updatedate, type: DateTime # Date
   field :enddate, type: DateTime # Date
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: String
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String
end