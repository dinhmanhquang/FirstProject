module Api
  class AdminsRegistrationsController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      admin_params = params.require(:admin).permit(:password, :password_confirmation, :email)
      @admin = Admin.new(admin_params)
      if @admin.save
        head :ok
      else
        @error_message = @admin.errors.messages
        render json: { error_message: @error_message }, status: :unprocessable_entity
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
