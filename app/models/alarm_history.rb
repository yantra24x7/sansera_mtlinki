class AlarmHistory
   include Mongoid::Document
   include Mongoid::Search
   include Mongoid::FullTextSearch
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
   
   search_in :L0Name, :message#, :updatedate
   search_in :message 
#   search_in :updatedate
#   search_in :number
  # fulltext_search_in :L0Name, :message#, :updatedate, :enddate
  # search_in :message, index: :_unit_keywords
 
#  search_in :search_data

#  def search_data
    # concatenate all String fields' values
#    self.attributes.select{|k,v| v.is_a?(String) }.values.join(' ')
#  end
#   fulltext_search_in :message, :L0Name

# fulltext_search_in :L1Name, :message, :index_name => 'gallery_index'

#   index({ L1Name: 1, L0Name: 1, number: 1, updatedate: 1, message: 1, type: 1 })
#   index({ enddate: 1})
#   index({ updatedate: -1, L1Name: 1, L0Name: 1, type: 1, number: 1})
#   index({ L1Name: 1, updatedate: -1,number: 1, type:1, L0Name: 1, timespan:1, level: 1, message: 1})
#   index({ updatedate: -1, enddate: 1, L1Name: 1})
#   index({ L0Name: 1, updatedate: -1})
   
end
