class L1Pool
   include Mongoid::Document
   include Mongoid::Timestamps
   include Mongoid::Paranoia

   store_in collection: "L1_Pool"

   field :L1Name, type: String
   field :updatedate, type: DateTime
   field :enddate, type: DateTime
   field :timespan, type: Integer
   field :signalname, type: String
   field :value, type: String
   field :filter, type: String
   field :TypeID, type: String
   field :Judge, type: String
   field :Error, type: String
   field :Warning, type: String
   field :deleted_at, type: DateTime
end
