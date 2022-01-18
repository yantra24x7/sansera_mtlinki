# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
#env :PATH, ENV['PATH']
#set :output, "/home/ubuntu/Rails/sansera_mtlinki/log/cron_log.log"
set :output, "log/cron_log.log"
env :PATH, ENV['PATH']
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

#every 1.day, at: '12:10 am' do
#  runner "Shift.delayed_job", :environment => :development
#end

#every 2.minutes do
#  runner "CurrentStatus.current_shift_report", :environment => :development
#end

every 1.day, at: '12:10 am' do
#  runner "L1PoolOpened.cron_delay", :environment => :development
end

every 15.minutes do
 # runner "NotificationSetting.sent_notification", :environment => :development
end


every 3.minutes do
 # runner "NotificationSetting.dashboard", :environment => :development
end

every 60.minutes do
#  runner "L1PoolOpened.j_c",:environment => :development
end
 
