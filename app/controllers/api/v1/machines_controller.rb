module Api
  module V1
    class MachinesController < ApplicationController
	    
	    def index
	    	machines = L0Setting.all
                machine_list = machines.map{|i| [id: i[:id], L0Name: i[:L0Name], ip: i[:NetworkSetting][:IpAddress], line: i[:line]]}
	    	render json: machine_list.flatten
	    end
            def machine_update
              
               if L0Setting.where(L0Name: params[:machine]).present?    
                l0_setting = L0Setting.where(L0Name: params[:machine]).first.update(line: params[:line])
                render json: l0_setting
               else
                render json: false
               end         
            end
            def notification_setting
             if NotificationSetting.where(L0Name: params[:machine]).present? 
              data = NotificationSetting.where(L0Name: params[:machine]).first
              data[:mean_time] = (data.mean_time/60).to_i
              render json: {status: true, data: data}
             else
              render json: {status: false, data: nil}
             end
            end

            def add_notification
              if NotificationSetting.where(L0Name: params[:machine]).present?
               render json: false
              else
              notifi_time = (params[:mean_time].to_i * 60).to_i
              notification = NotificationSetting.create(L0Name: params[:machine], l0_setting_id: params[:l0_setting_id], mean_time: notifi_time, active: false)
              notification[:mean_time] = (notification.mean_time/60).to_i
              render json: notification
              end
            end

            def update_notification
             
              if NotificationSetting.where(L0Name: params[:machine]).present? 
               notifi_time = (params[:mean_time].to_i * 60).to_i
               notification = NotificationSetting.where(L0Name: params[:machine]).first.update(mean_time: notifi_time)
       
               render json: notification
              else
              render json: false
              end
            end
           
            def change_status_notification
             if NotificationSetting.find(params[:id]).present?
               status =  NotificationSetting.find(params[:id]).update(active: params[:status])
               render json: status
             else
               render json: false
             end
            end
	    def machine_status
	    	status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
	    	data = L1SignalPoolActive.where(:signalname.in => status)
	    	data1 = []
	      	data.group_by{|d| d[:L1Name]}.each do |key, value|
	      		ss = value.select{|a| a[:value] == true}
	    		data1  << {"#{key}":  ss}
	    	end
        	render json: data1
	    end

	    def single_machine_detail
		    shift = Shift.current_shift
		    date = Date.today.to_s
       		case
		    when shift.start_day == 1 && shift.end_day == 1
		      start_time = (date+" "+shift.start_time).to_time
		      end_time = (date+" "+shift.end_time).to_time
		    when shift.start_day == 1 && shift.end_day == 2
		       if Time.now.strftime("%p") == "AM"
		        start_time = (date+" "+shift.start_time).to_time-1.day
		        end_time = (date+" "+shift.end_time).to_time
		      else
		        start_time = (date+" "+shift.start_time).to_time
		        end_time = (date+" "+shift.end_time).to_time+1.day
		      end
		    else
		      start_time = (date+" "+shift.start_time).to_time
		      end_time = (date+" "+shift.end_time).to_time
		    end
		    # byebug
         	L1SignalPool.where(nil)		    
	    end
    end
  end
end
