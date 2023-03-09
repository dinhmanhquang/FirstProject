module Api
  class UsersRegistrationsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      user_params = params.require(:user).permit(:password, :password_confirmation, :email)
      @user = User.new(user_params)
      if @user.save
        head :ok
      else
        @error_message = @user.errors.messages
        render json: { error_message: @error_message }, status: :unprocessable_entity
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
