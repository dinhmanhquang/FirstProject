class AdminMailer < ApplicationMailer
  def reset_password_instruction(admin, token, host)
    @token = token
    @host = host
    @admin = admin
    mail(to: @admin.email, subject: I18n.t('reset_password.email_subject'))
  end
end
