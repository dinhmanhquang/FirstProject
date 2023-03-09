module Api
  class UsersPasswordsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    before_action :doorkeeper_authorize!, only: ['create']

    before_action :current_user_authenticate, only: ['create']

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      if current_user.valid_password?(params[:old_password])
        if current_user.update(password: params[:new_password])
          head :ok
        else
          render json: { error_message: current_user.errors.full_messages.join(',') }, status: :unprocessable_entity
        end
      else
        render json: { error_message: I18n.t('devise.passwords.old_password_mismatch') }, status: :unprocessable_entity
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
