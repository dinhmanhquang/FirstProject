module Api
  class UsersResetPasswordRequestsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      user = User.find_by(email: params[:email])
      if user.present?

        user.send_confirmation_instructions and return unless user.confirmed?

        user.send_reset_password_instructions
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
