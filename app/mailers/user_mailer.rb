class UserMailer < ApplicationMailer
  def reset_password_instruction(user, token, host)
    @token = token
    @host = host
    @user = user
    mail(to: @user.email, subject: I18n.t('reset_password.email_subject'))
  end
end
