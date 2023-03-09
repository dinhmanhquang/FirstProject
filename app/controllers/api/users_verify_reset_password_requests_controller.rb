module Api
  class UsersVerifyResetPasswordRequestsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      token = Devise.token_generator.digest(User, :reset_password_token, params[:reset_token])
      user = User.find_by(reset_password_token: token)

      if user.blank? || params[:reset_token].blank? || params[:password].blank? || params[:password_confirmation].blank?
        @error_message = I18n.t('reset_password.invalid_token')
      elsif !user.reset_password_period_valid?
        @error_message = I18n.t('errors.messages.expired')
      elsif user.reset_password(params[:password], params[:password_confirmation])
      else
        @error_message = user.errors.full_messages
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
