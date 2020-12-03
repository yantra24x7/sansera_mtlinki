class L0Setting
   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "L0_Setting" 

   field :FormateVersion, type: Integer
   field :CollectorIndex, type: Integer
   field :Index, type: Integer
   field :L0Name, type: String
   field :L0EnName, type: String
   field :L0JpName, type: String
   field :L0CnName, type: String
   field :MachineType, type: Integer
   field :ControlType, type: Array
   field :Connect, type: Mongoid::Boolean
   field :SamplingCycle, type: Integer
   field :CncMaxPath, type: Integer
   field :SpindleUnit, type: Integer
   field :NetworkSetting, :type => Hash
   field :Signal_Setting, type: Array
   field :OperationHistorySchedule, :type => Hash
   field :MacroCaputreDefine, type: String
   field :TriggerDefine, type: String
   field :ChoseMachineNodeID, type: String
   field :RobotController, type: Integer
   field :MTConnectDeviceName, type: String
   field :MTConnectUuid, type: String
   field :unit, type: String
   belongs_to :OperatorAllocation
end
