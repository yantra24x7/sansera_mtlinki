class ProgramHistory
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "Program_History"

   field :L1Name, type: String
   field :L0Name, type: String
   field :path, type: String
   field :mainprogflg, type: Boolean
   field :mainprog, type: String
   field :runningprog, type: String
   field :timespan, type: Integer
   field :updatedate, type: DateTime
   field :enddate, type: DateTime
  
   


end
