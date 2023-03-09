module Api
  class AdminsVerifyResetPasswordRequestsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      token = Devise.token_generator.digest(Admin, :reset_password_token, params[:reset_token])
      admin = Admin.find_by(reset_password_token: token)

      if admin.blank? || params[:reset_token].blank? || params[:password].blank? || params[:password_confirmation].blank?
        @error_message = I18n.t('reset_password.invalid_token')
      elsif !admin.reset_password_period_valid?
        @error_message = I18n.t('errors.messages.expired')
      elsif admin.reset_password(params[:password], params[:password_confirmation])
      else
        @error_message = admin.errors.full_messages
      end
      if @error_message.present?
        render json: { error_message: @error_message }, status: :unprocessable_entity
      else
        head :ok
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
