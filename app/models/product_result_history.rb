class ProductResultHistory
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "ProductResult_History"

    field :L1Name, type: String
    field :updatedate, type: DateTime
    field :enddate, type: DateTime
    field :timespan, type: Integer
    field :resultflag, type: Boolean
    field :productserialnumber, type: String
    field :productname, type: String
    field :productresult, type: String
    field :productresult_accumulate, type: String
   # field :Judge, type: String
   # field :Error, type: String
   # field :Warning, type: String

end
