class ProductResultHistory
   include Mongoid::Document
   include Mongoid::Timestamps
   include Mongoid::Paranoia

   store_in collection: "ProductResult_History"

    field :L1Name, type: String
    field :updatedate, type: DateTime
    field :enddate, type: DateTime
    field :timespan, type: Integer
    field :resultflag, type: Boolean
    field :productserialnumber, type: String
    field :productname, type: String
    field :productresult, type: Integer
    field :productresult_accumulate, type: String
    field :cycle_time, type: Integer
    field :cutting_time, type: Integer
    field :program_number, type: String  
    field :accept_count, type: Integer
    field :reject_count, type: Integer
    field :is_verified, type: Mongoid::Boolean
    field :deleted_at, type: DateTime

    index({updatedate: 1, enddate: 1, productresult: 1 })

end
