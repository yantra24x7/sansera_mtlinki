class NotificationMailer < ApplicationMailer
 def notification(data)
    @stop_machine = data
    mail(to: 'manisankar.gnanasekaran@adcltech.com,thooyavan.venkat@adcltech.com', subject: 'Notification Alert')
  end
end
